param([string]$ImageArchive = '')
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
if ($ImageArchive) { $ImageArchive = (Resolve-Path -LiteralPath $ImageArchive).Path }
$package = Join-Path $PSScriptRoot 'flipper-one-windows-v0.2.zip'
$expected = '6ff23dd736ccc88ce16b2910bc636e6b680797b78a82c1ab67e14b19eb453d09'
$ready = Join-Path $PSScriptRoot 'ready'
if (!(Test-Path -LiteralPath $package)) {
    Write-Host 'Reconstructing the Flipper One package from repository parts...'
    $partial = "$package.partial"
    $outputStream = [System.IO.File]::Open($partial, [System.IO.FileMode]::Create)
    try {
        foreach ($number in 1..10) {
            $part = Join-Path $PSScriptRoot ('package-parts\part-{0:D2}.bin' -f $number)
            if (!(Test-Path -LiteralPath $part)) { throw "Missing part: $part. Download the complete repository ZIP." }
            $inputStream = [System.IO.File]::OpenRead($part)
            try { $inputStream.CopyTo($outputStream) } finally { $inputStream.Dispose() }
        }
    } finally { $outputStream.Dispose() }
    if ((Get-FileHash -LiteralPath $partial -Algorithm SHA256).Hash.ToLowerInvariant() -ne $expected) {
        throw 'Package checksum mismatch. Download the complete repository ZIP again.'
    }
    Move-Item -LiteralPath $partial -Destination $package -Force
}
if ((Get-FileHash -LiteralPath $package -Algorithm SHA256).Hash.ToLowerInvariant() -ne $expected) {
    throw 'Package checksum mismatch.'
}
Write-Host 'Unpacking the verified package...'
Expand-Archive -LiteralPath $package -DestinationPath $ready -Force
$launcher = Join-Path $ready 'Start-Flipper.ps1'
if ($ImageArchive) { & $launcher -ImageArchive $ImageArchive } else { & $launcher }
