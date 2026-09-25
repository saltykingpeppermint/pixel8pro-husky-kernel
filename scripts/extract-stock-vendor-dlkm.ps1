# List + extract vendor_dlkm/system_dlkm from the stock factory image zip
$zip = 'D:\pixel8pro-factory\out\husky_beta-bp31.250610.009\image-husky_beta-bp31.250610.009.zip'
$dest = 'D:\pixel8pro-factory\out\husky_beta-bp31.250610.009'
Add-Type -A 'System.IO.Compression.FileSystem'
$z = [IO.Compression.ZipFile]::OpenRead($zip)
Write-Host '--- entries (dlkm/boot/dtbo):'
$z.Entries | Where-Object { $_.Name -match 'dlkm' } | ForEach-Object { Write-Host $_.Name $_.Length }
foreach ($e in $z.Entries) {
    if ($e.Name -match 'vendor_dlkm.*\.img$') {
        $out = Join-Path $dest ($e.Name -replace '\.img$', '-stock.img')
        Write-Host "extracting $($e.Name) -> $out"
        [IO.Compression.ZipFileExtensions]::ExtractToFile($e, $out, $true)
    }
}
$z.Dispose()
Write-Host '--- done'
Get-ChildItem "$dest\*dlkm*" | Select-Object Name, Length
