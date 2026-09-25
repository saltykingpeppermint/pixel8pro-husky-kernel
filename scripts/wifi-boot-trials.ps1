# Reboot trial loop: N reboots, capture wifi enum verdict each boot.
param([int]$Trials = 3)
$log = "C:\Users\King\Documents\Default Project\out\wifi-boot-trials.log"
"=== wifi boot trials started $(Get-Date -Format s) x$Trials ===" | Out-File -FilePath $log -Encoding utf8
for ($i = 1; $i -le $Trials; $i++) {
    adb reboot | Out-Null
    Start-Sleep -Seconds 20
    adb wait-for-device
    adb root | Out-Null
    Start-Sleep -Seconds 3
    adb wait-for-device
    # wait for boot_completed (poll up to 90s)
    for ($w = 0; $w -lt 45; $w++) {
        $bc = adb shell getprop sys.boot_completed 2>$null
        if ("$bc".Trim() -eq "1") { break }
        Start-Sleep -Seconds 2
    }
    $up = adb shell "cut -d' ' -f1 /proc/uptime"
    $mod = adb shell "grep -c bcmdhd4398 /proc/modules"
    $wlan = adb shell "ls /sys/class/net" | Select-String -Pattern "wlan"
    adb shell "dmesg" | Out-File -FilePath "C:\Users\King\Documents\Default Project\out\dmesg-trial-$i.log" -Encoding utf8
    $verdict = "trial $i : uptime=$($up.Trim()) bcmdhd_loaded=$($mod.Trim()) wlan=$($wlan -join ',')"
    $verdict | Out-File -FilePath $log -Append -Encoding utf8
}
"=== done $(Get-Date -Format s) ===" | Out-File -FilePath $log -Append -Encoding utf8
