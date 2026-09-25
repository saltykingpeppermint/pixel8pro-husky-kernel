# monitor-wsl.ps1 — WSL health watchdog + kernel-build guardian.
#
# Runs as an opencode background shell. Exits ONLY on a terminal state;
# the exit wakes the assistant with the final output, so the user does not
# have to ask for updates. Durable state goes to out/monitor.log + out/build.log.
#
# Exit codes: 0 = build OK | 10 = build failed (needs eyes)
#             20 = disk full | 30 = WSL unrecoverable (needs eyes)
#             35 = vhdx locked by leaked VM -> REBOOT REQUIRED
#             40 = relaunch limit | 50 = monitor bug
param(
    [int]$IntervalSec = 60,
    [int]$BuildAttemptLimit = 3,
    [int]$StallMinutes = 25,
    [long]$DiskMinBytes = 10GB
)

$ErrorActionPreference = 'Stop'

# ProcessStartInfo.ArgumentList (used by Invoke-Wsl/Start-Build) only exists
# on PowerShell 7+ (.NET Core). On Windows PowerShell 5.1 it is $null and the
# very first probe dies with "You cannot call a method on a null-valued
# expression." Fail loudly instead, and only when actually running a loop.
if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Error 'monitor-wsl.ps1 requires PowerShell 7+ (pwsh -File ...), not powershell.exe'
    exit 50
}

$Project        = 'C:\Users\King\Documents\Default Project'
$OutDir         = Join-Path $Project 'out'
$LogPath        = Join-Path $OutDir 'monitor.log'
$BuildLog       = Join-Path $OutDir 'build.log'
$UbuntuVhdx     = 'D:\WSL\Ubuntu-24.04\ext4.vhdx'
$FsckScript     = '/mnt/c/Users/King/Documents/Default Project/scripts/fsck-ubuntu.sh'
$BuildScript    = '/mnt/c/Users/King/Documents/Default Project/scripts/build-wrapper.sh'

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

$script:buildLaunched   = $false
$script:buildAttempts   = 0
$script:vhdxLocked      = $false
$script:buildLastChange = $null
$script:lastStallKill   = $null
$script:aliveMisses     = 0
$script:transportFails  = 0

function Log([string]$msg) {
    $line = '{0} {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $msg
    Add-Content -Path $LogPath -Value $line
    Write-Host $line   # host stream: never pollutes function return values
}

function Test-VmRunning {
    return (@(Get-Process vmmem,vmmemWSL -ErrorAction SilentlyContinue).Count -gt 0)
}

# Run wsl.exe with proper per-argument quoting (space-safe), async stream
# reads (no pipe-deadlock) and a hard timeout that kills the whole tree.
function Invoke-Wsl {
    param([string[]]$WslArgs, [int]$TimeoutMs = 150000)
    $psi = [System.Diagnostics.ProcessStartInfo]::new()
    $psi.FileName = 'wsl.exe'
    foreach ($a in $WslArgs) { [void]$psi.ArgumentList.Add($a) }
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $p = [System.Diagnostics.Process]::Start($psi)
    $outTask = $p.StandardOutput.ReadToEndAsync()
    $errTask = $p.StandardError.ReadToEndAsync()
    $timed = -not $p.WaitForExit($TimeoutMs)
    if ($timed) {
        try { $p.Kill($true) } catch {}
        [void]$p.WaitForExit(10000)
    }
    $out = ''; $err = ''; $code = -1
    try { $out = $outTask.Result } catch {}
    try { $err = $errTask.Result } catch {}
    try { $code = $p.ExitCode } catch {}
    return [pscustomobject]@{ Code = $code; TimedOut = $timed; Out = $out; Err = $err }
}

# Boot probe. $RequireVm: when watching a running build, only probe if the VM
# is already up (attaching = safe); never start a second cold boot while a
# cold boot could be in flight (that concurrency is what broke us originally).
function Test-Ubuntu {
    param([bool]$RequireVm = $false)
    if ($RequireVm -and -not (Test-VmRunning)) { return $false }
    $r = Invoke-Wsl @('-d', 'Ubuntu-24.04', '--', 'echo', 'MONITOR_OK') 150000
    $ok = (-not $r.TimedOut -and $r.Code -eq 0 -and $r.Out -match 'MONITOR_OK')
    if (-not $ok) {
        # wsl.exe leaks UTF-16LE into its streams; strip NULs for a readable log.
        $e = (($r.Err + ' ' + $r.Out).Replace([char]0, ' ')) -replace '\s+', ' '
        if ($e.Length -gt 220) { $e = $e.Substring(0, 220) }
        Log ("PROBE_FAIL code={0} timedOut={1} detail={2}" -f $r.Code, $r.TimedOut, $e.Trim())
    }
    return $ok
}

# Force-recycle a Windows service without ever blocking forever on Stop
# (StopPending hang bit us once: Restart-Service waited >5 minutes).
# Modes:
#   Force - kill the process tree, then Start-Service (proven safe for WslService).
#   Scm   - SCM-mediated Restart-Service -Force (proven safe for vmcompute).
# NEVER raw-kill vmcompute: both BSODs (bugcheck 0x3B, identical fault offset
# ...596c) landed inside its force-recycle window.
function Recycle-Service {
    param([string]$Name, [ValidateSet('Force','Scm')][string]$Mode = 'Force')
    Log ("REPAIR: recycle {0} mode={1} start" -f $Name, $Mode)
    if ($Mode -eq 'Scm') {
        try { Restart-Service -Name $Name -Force -ErrorAction Stop } catch { Log ("REPAIR: Restart-Service {0} threw: {1}" -f $Name, $_) }
        Start-Sleep -Seconds 4
        Log ("REPAIR: service {0} -> {1}" -f $Name, (Get-Service -Name $Name).Status)
        return
    }
    Get-Process -Name $Name -ErrorAction SilentlyContinue | ForEach-Object {
        Log ("REPAIR: force-killing {0} pid={1}" -f $_.ProcessName, $_.Id)
        try { $_.Kill($true) } catch {}
    }
    $deadline = (Get-Date).AddSeconds(45)
    while ((Get-Date) -lt $deadline) {
        $st = (Get-Service -Name $Name).Status
        if ($st -eq 'Stopped') { break }
        Start-Sleep -Seconds 3
    }
    $startDeadline = (Get-Date).AddSeconds(30)
    while ((Get-Date) -lt $startDeadline) {
        try { Start-Service -Name $Name -ErrorAction Stop; break } catch { Start-Sleep -Seconds 3 }
    }
    Start-Sleep -Seconds 4
    Log ("REPAIR: service {0} -> {1}" -f $Name, (Get-Service -Name $Name).Status)
}

# True if the Ubuntu vhdx can be opened exclusively (no leaked VM holding it).
function Test-VhdxFree {
    try {
        [System.IO.File]::Open($UbuntuVhdx, 'Open', 'ReadWrite', 'None').Dispose()
        return $true
    } catch {
        Log 'VHDX_LOCKED: a leaked/zombie VM is holding ext4.vhdx (unkillable without reboot)'
        return $false
    }
}

# Shut down ALL WSL utility VMs (logging the result - it used to be discarded)
# and verify the disk actually came free. Handles release asynchronously, so
# retry briefly. A stuck/orphaned vmmem can survive shutdown - only a reboot
# clears those, and callers surface that as exit 35.
function Reset-Vhdx {
    $s = Invoke-Wsl @('--shutdown') 60000
    Log ("REPAIR: wsl --shutdown code={0} timedOut={1}" -f $s.Code, $s.TimedOut)
    Start-Sleep -Seconds 5
    for ($i = 1; $i -le 3; $i++) {
        if (Test-VhdxFree) { Log 'REPAIR: vhdx verified free'; return $true }
        Start-Sleep -Seconds 4
    }
    return $false
}

# Ordered least-invasive-first playbook. Returns $true if Ubuntu boots again.
function Repair-WSL {
    Log 'REPAIR: === playbook start ==='
    if (Test-BuildAlive) {
        Log 'REPAIR: stopping detached build wrapper + bazel client first (avoid mid-write kill)'
        $null = Invoke-Wsl @('-d', 'Ubuntu-24.04', '--', 'bash', '-c',
                "pkill -TERM -f '[b]uild-wrapper.sh'; pkill -TERM -f '[b]azel.*shusky_dist'") 15000
        Start-Sleep -Seconds 3
    }

    # Phase 0: clean slate - clear leaked VMs from failed probes and PROVE the
    # disk is free before anything else (a held vhdx makes every later step fail
    # with sharing violations and masquerades as a boot problem).
    if (-not (Reset-Vhdx)) { $script:vhdxLocked = $true; return $false }

    Log 'REPAIR: step=plain-retry-probe'
    if (Test-Ubuntu) { Log 'REPAIR: OK after plain retry'; return $true }

    # Phase 1: fs damage (build killed mid-write) is the prime suspect, and the
    # rescue/fsck path must run BEFORE service recycles: a WslService force-kill
    # can orphan leaked VMs and strand the disk, so do fsck while shutdown can
    # still clear them.
    Log 'REPAIR: step=rescue-probe'
    $rescue = Invoke-Wsl @('-d', 'WslTest', '--', 'echo', 'RESCUE_OK') 150000
    $rescueOk = (-not $rescue.TimedOut -and $rescue.Code -eq 0 -and $rescue.Out -match 'RESCUE_OK')
    Log ("REPAIR: rescue distro boots = {0}" -f $rescueOk)

    if ($rescueOk) {
        if (-not (Reset-Vhdx)) { $script:vhdxLocked = $true; return $false }
        Log 'REPAIR: attaching Ubuntu vhdx to rescue distro for fsck'
        $att = Invoke-Wsl @('--mount', $UbuntuVhdx, '--vhd', '--bare') 60000
        Log ("REPAIR: attach code={0} {1}" -f $att.Code, $att.Out.Trim())
        if ($att.Code -ne 0) { $script:vhdxLocked = $true; return $false }

        # Alpine has no bash; run the POSIX script with sh. e2fsck -f on a big
        # sparse vhdx can take hours - a killed e2fsck would be worse than
        # waiting, hence the generous 4h cap.
        $fs = Invoke-Wsl @('-d', 'WslTest', '--', 'sh', $FsckScript) 14400000
        Log ("REPAIR: fsck run code={0} timedOut={1} (details in out/fsck.log)" -f $fs.Code, $fs.TimedOut)

        $det = Invoke-Wsl @('--unmount', $UbuntuVhdx) 60000
        Log ("REPAIR: detach code={0}" -f $det.Code)
        Start-Sleep -Seconds 3

        Log 'REPAIR: step=post-fsck probe'
        if (Test-Ubuntu) { Log 'REPAIR: OK after fsck'; return $true }
        Log 'REPAIR: still failing after fsck'
    } else {
        Log 'REPAIR: rescue distro did not boot - trying service recycles'
    }

    # Phase 2: service recycles (fallback). WslService force-recycle was this
    # morning's actual fix; vmcompute only via SCM (raw-kill crashed the box).
    if ($script:conservative) {
        Log 'REPAIR: SERVICE RECYCLES SKIPPED (conservative: prior instance died inside a repair playbook)'
        return $false
    }
    Log 'REPAIR: step=wslservice-recycle'
    Recycle-Service 'WslService' -Mode Force
    if (-not (Reset-Vhdx)) { $script:vhdxLocked = $true; return $false }
    if (Test-Ubuntu) { Log 'REPAIR: OK after WslService recycle'; return $true }

    Log 'REPAIR: step=vmcompute-recycle'
    Recycle-Service 'vmcompute' -Mode Scm
    if (-not (Reset-Vhdx)) { $script:vhdxLocked = $true; return $false }
    if (Test-Ubuntu) { Log 'REPAIR: OK after vmcompute recycle'; return $true }

    return $false
}

function Start-Build {
    # LAUNCH DETACHED: the wrapper must survive THIS process dying. An opencode
    # session restart kills the background monitor AND its wsl.exe children —
    # that is exactly what interrupted build attempt 2 (log frozen at 00:03,
    # bazel wrapper gone, server idle with the compile action dead). setsid+nohup
    # inside WSL reparents the wrapper to init, so only a VM shutdown stops it.
    #
    # TRAP (cost 3 launches tonight): if wsl.exe exits the instant the job is
    # backgrounded, WSL tears the process group down BEFORE setsid() detaches
    # it — the wrapper dies before writing anything. Keep the session open a
    # few seconds (`sleep 4`) so the detach completes while the connection is
    # alive. The path's space is passed backslash-escaped (proven working;
    # single quotes did not survive the hand-off).
    $cmd = "nohup setsid bash $($BuildScript -replace ' ', '\ ') >/dev/null 2>&1 </dev/null & sleep 4; echo DETACHED_OK"
    $r = Invoke-Wsl @('-d', 'Ubuntu-24.04', '--', 'bash', '-c', $cmd) 30000
    if ($r.Out -notmatch 'DETACHED_OK') {
        Log ("WARN: detached launch transport failed rc={0} out={1} err={2}" -f $r.Code, $r.Out.Trim(), $r.Err.Trim())
        return $false
    }
    # Positive confirmation: a FRESH '=== BUILD START ===' line in build.log.
    $fresh = $false
    if (Test-Path $BuildLog) {
        $bs = Select-String -Path $BuildLog -Pattern '^=== BUILD START ' -ErrorAction SilentlyContinue |
              Select-Object -Last 1
        if ($bs) {
            try {
                $ts = $bs.Line.Substring(16, 19)   # '=== BUILD START ' is 16 chars
                $t  = [datetime]::ParseExact($ts, 'yyyy-MM-ddTHH:mm:ss', $null)
                $fresh = ((Get-Date) - $t).TotalMinutes -lt 3
            } catch {}
        }
    }
    if ($fresh) { Log 'LAUNCH: wrapper confirmed detached (BUILD START written)' }
    else        { Log 'WARN: wrapper launched but no fresh BUILD START in build.log yet' }
    return $fresh
}

function Get-BuildMarker {
    if (-not (Test-Path $BuildLog)) { return $null }
    $m = Select-String -Path $BuildLog -Pattern 'BUILD_EXIT=' -ErrorAction SilentlyContinue |
         Select-Object -Last 1
    if ($m -and $m.Line -match 'BUILD_EXIT=(\d+)') {
        return [pscustomobject]@{ Line = $m.Line; Rc = [int]$Matches[1] }
    }
    return $null
}

# Is the detached wrapper still running inside WSL? The [b] trick keeps the
# probe's own `bash -c` command line from matching pgrep -f (it would report
# ALIVE forever). A failed/timeout wsl call (VM wedged) reads as not-alive,
# which routes into the existing boot-probe -> repair -> relaunch flow.
#
# TWO-STRIKE: under heavy compile load the interop call itself flakes
# (2026-09-25 03:17-03:34: single negative probes caused duplicate launches
# while the wrapper was alive). A wrapper is only declared dead after two
# consecutive negatives; positives reset the counter.
function Test-BuildAlive {
    $r = Invoke-Wsl @('-d', 'Ubuntu-24.04', '--', 'bash', '-c',
         "pgrep -f '[b]uild-wrapper.sh' >/dev/null && echo ALIVE") 45000
    if ($r.Out -match 'ALIVE') { $script:aliveMisses = 0; return $true }
    $script:aliveMisses++
    Log ("WARN: liveness probe negative ({0}/2)" -f $script:aliveMisses)
    if ($script:aliveMisses -ge 2) { $script:aliveMisses = 0; return $false }
    return $true   # uncertain -> treat as alive this cycle (warn + heartbeat)
}

try {
    # Detect an abrupt prior death (BSOD/power-loss): the previous instance's
    # last log line predates the current Windows boot. Read BEFORE appending.
    $script:conservative = $false
    $lastLine = $null
    try { $lastLine = Get-Content $LogPath -Tail 1 -ErrorAction SilentlyContinue } catch {}
    if ($lastLine -and $lastLine.Length -ge 19) {
        $boot = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
        $lastTs = [datetime]::ParseExact($lastLine.Substring(0, 19), 'yyyy-MM-dd HH:mm:ss', $null)
        if ($boot -gt $lastTs) {
            Log ("WARN: prior monitor instance died abruptly (last='{0}'; boot={1})" -f $lastLine, $boot)
            if ($lastLine -like '*REPAIR:*') {
                $script:conservative = $true
                Log 'MODE=CONSERVATIVE (prior death inside repair playbook - suspected crash trigger; service recycles disabled this run)'
            }
        }
    }
    Log ('=== WSL monitor started (interval={0}s, attempts limit={1}) ===' -f $IntervalSec, $BuildAttemptLimit)

    while ($true) {
        # --- disk guard: a full D: would silently kill the build ---
        $d = Get-PSDrive -Name D -ErrorAction SilentlyContinue
        if ($d -and $d.Free -lt $DiskMinBytes) {
            Log ("FINAL_STATUS=DISK_FULL freeGB={0}" -f [math]::Round($d.Free / 1GB, 1))
            exit 20
        }

        # --- build outcome is authoritative once the wrapper recorded it ---
        $marker = Get-BuildMarker
        if ($marker) {
            if ($marker.Rc -eq 0) { Log 'FINAL_STATUS=BUILD_OK'; exit 0 }
            Log ("FINAL_STATUS=BUILD_FAILED {0}" -f $marker.Line)
            exit 10
        }

        # --- no marker: is the detached wrapper still alive inside WSL? ---
        if (Test-BuildAlive) {
            # Stall watchdog: while building, build.log must keep advancing
            # (bazel prints a progress line about every minute). Frozen log +
            # live wrapper = wedged build -> kill the bazel client; the wrapper
            # then records BUILD_EXIT=<rc> and the marker path takes over.
            $mt = $null
            if (Test-Path $BuildLog) { $mt = (Get-Item $BuildLog).LastWriteTime }
            $frozen = $mt -and $script:buildLastChange -and ($mt -eq $script:buildLastChange)
            $aged   = $mt -and ((Get-Date) - $mt).TotalMinutes -ge $StallMinutes
            $cool   = (-not $script:lastStallKill) -or
                      (((Get-Date) - $script:lastStallKill).TotalMinutes -ge $StallMinutes)
            if ($frozen -and $aged -and $cool) {
                Log ("STALL: build.log frozen {0:N0} min with wrapper alive -> killing bazel client" -f
                     ((Get-Date) - $mt).TotalMinutes)
                $null = Invoke-Wsl @('-d', 'Ubuntu-24.04', '--', 'bash', '-c',
                        "pkill -TERM -f '[b]azel.*shusky_dist'; pkill -TERM -f '[b]uild_shusky'") 20000
                $script:lastStallKill = Get-Date
            } elseif ($mt) {
                $script:buildLastChange = $mt
            }
            Log 'HEARTBEAT: build running, VM up'
            Start-Sleep -Seconds $IntervalSec
            continue
        }
        if ($script:buildLaunched) {
            Log 'WARN: launched wrapper no longer running and no BUILD_EXIT marker (died without recording outcome)'
            $script:buildLaunched = $false
        }

        # --- need (re)launch: make sure WSL boots at all, then start build ---
        if (-not (Test-Ubuntu)) {
            Log 'boot probe FAILED -> remediation'
            if (-not (Repair-WSL)) {
                if ($script:vhdxLocked) {
                    Log 'FINAL_STATUS=VHDX_LOCKED_REBOOT_REQUIRED (leaked VM holds ext4.vhdx; only a reboot clears it)'
                    exit 35
                }
                Log 'FINAL_STATUS=UNRECOVERABLE_WSL'
                exit 30
            }
        }

        if ($script:buildAttempts -ge $BuildAttemptLimit) {
            Log 'FINAL_STATUS=RELAUNCH_LIMIT (build keeps dying without a BUILD_EXIT marker)'
            exit 40
        }
        Log ("LAUNCH: kernel build attempt {0}/{1} (counts only on confirmed start)" -f
             ($script:buildAttempts + 1), $BuildAttemptLimit)
        if (Start-Build) {
            $script:buildAttempts++
            $script:transportFails = 0
            $script:buildLaunched = $true
            $script:buildLastChange = $null
            Start-Sleep -Seconds 90   # cold boot + bazel-server grace before probing
        } else {
            # Transport failure (WSL service flake) must NOT burn a build
            # attempt — tonight two rc=-1 timeouts consumed 2 of 3 attempts.
            $script:transportFails++
            Log ("WARN: launch transport failure {0}/5 consecutive" -f $script:transportFails)
            if ($script:transportFails -ge 5) {
                Log 'FINAL_STATUS=RELAUNCH_LIMIT (launch transport keeps failing)'
                exit 40
            }
            Start-Sleep -Seconds 30
        }
        continue
    }
} catch {
    Log ("FINAL_STATUS=EXCEPTION {0}" -f $_)
    exit 50
}
