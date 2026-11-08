param([string]$QemuDirectory = '', [int]$MemoryMB = 3072, [string]$ImageArchive = '')
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
if ($ImageArchive) { $ImageArchive = (Resolve-Path -LiteralPath $ImageArchive).Path }
Set-Location -LiteralPath $PSScriptRoot

function Find-Qemu {
    if ($QemuDirectory) {
        $candidate = Join-Path $QemuDirectory 'qemu-system-aarch64.exe'
        if (Test-Path -LiteralPath $candidate) { return $candidate }
        throw "No qemu-system-aarch64.exe in $QemuDirectory"
    }
    $command = Get-Command 'qemu-system-aarch64.exe' -ErrorAction SilentlyContinue
    if ($command) { return $command.Source }
    foreach ($folder in @("$env:ProgramFiles\qemu", "${env:ProgramFiles(x86)}\qemu")) {
        $candidate = Join-Path $folder 'qemu-system-aarch64.exe'
        if (Test-Path -LiteralPath $candidate) { return $candidate }
    }
    throw 'Install QEMU for Windows from https://www.qemu.org/download/#windows, then run Start.cmd again. Or use -QemuDirectory C:\path\to\qemu.'
}

$qemu = Find-Qemu
$qemuImg = Join-Path (Split-Path -Parent $qemu) 'qemu-img.exe'
if (!(Test-Path -LiteralPath $qemuImg)) { throw 'qemu-img.exe is missing from the QEMU installation.' }
if ($MemoryMB -lt 2048) { throw 'Use at least 2048 MB of guest memory.' }
foreach ($line in Get-Content -LiteralPath '.\SHA256SUMS') {
    if ($line -match '^([a-f0-9]{64})  (.+)$') {
        $expected = $Matches[1]
        $file = Join-Path $PSScriptRoot $Matches[2]
        if (!(Test-Path -LiteralPath $file)) { throw "Missing package file: $file" }
        if ((Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash.ToLowerInvariant() -ne $expected) {
            throw "Package checksum mismatch: $file"
        }
    }
}

$data = Join-Path $PSScriptRoot 'data'
New-Item -ItemType Directory -Path $data -Force | Out-Null
$raw = Join-Path $data 'flipper-one-2485.img'
$archive = Join-Path $data 'debian-512-flipper-one-2485.img.zst'
if ($ImageArchive) {
    if (!(Test-Path -LiteralPath $ImageArchive -PathType Leaf)) { throw "Image archive not found: $ImageArchive" }
    $archive = (Resolve-Path -LiteralPath $ImageArchive).Path
}
$url = 'https://dl-linux-images.flipp.dev/full-img/2485/debian-512-flipper-one-2485.img.zst'
$expectedImage = '222b81f078ea96fe3e832f76e700fcdae3fd10b192b2b1e36c7d2e9749bb4154'
if (!(Test-Path -LiteralPath $raw)) {
    Write-Host 'First start: allow at least 12 GB free disk space. The official download is about 2 GB.'
    if (!(Test-Path -LiteralPath $archive)) {
        & curl.exe --fail --location --retry 3 --output "$archive.part" $url
        if ($LASTEXITCODE -ne 0) { throw 'Image download failed. Run Start.cmd to retry.' }
        Move-Item -LiteralPath "$archive.part" -Destination $archive -Force
    }
    Write-Host 'Verifying the official SHA256...'
    if ((Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash.ToLowerInvariant() -ne $expectedImage) {
        throw "Image checksum mismatch. Remove $archive and start again."
    }
    Write-Host 'Decompressing the official 6 GiB disk...'
    & '.\tools\zstd.exe' -d --sparse -f $archive -o "$raw.partial"
    if ($LASTEXITCODE -ne 0) { throw 'Image decompression failed.' }
    if ((Get-Item -LiteralPath "$raw.partial").Length -ne 6442450944) { throw 'Wrong decompressed image size.' }
    Move-Item -LiteralPath "$raw.partial" -Destination $raw -Force
    Write-Host 'Official image ready.'
}
if ((Get-Item -LiteralPath $raw).Length -ne 6442450944) { throw 'The base image has an unexpected size.' }
$overlay = Join-Path $data 'session.qcow2'
if (!(Test-Path -LiteralPath $overlay)) {
    & $qemuImg create -f qcow2 -F raw -b $raw $overlay
    if ($LASTEXITCODE -ne 0) { throw 'Could not create the persistent QEMU overlay.' }
}
$flash = Join-Path $data 'uboot-env.img'
if (!(Test-Path -LiteralPath $flash)) {
    $stream = [System.IO.File]::Open($flash, [System.IO.FileMode]::CreateNew)
    try { $stream.SetLength(67108864) } finally { $stream.Dispose() }
}
if ((Get-Item -LiteralPath $flash).Length -ne 67108864) { throw 'The U-Boot environment flash must be 64 MiB.' }

Write-Host ''
Write-Host 'Choose 1-5 in the U-Boot menu in THIS console. Default: Desktop.'
Write-Host 'Panel: http://127.0.0.1:8899/  (wait for Linux to finish starting)'
Write-Host 'SSH: ssh -p 2222 user@127.0.0.1   Password: user'
Write-Host 'The QEMU window is the external display. The small panel is in your browser.'
Write-Host 'Shut down Linux with: sudo poweroff. Keep the console open.'
Write-Host ''
$qemuArgs = @(
    '-machine', 'virt', '-accel', 'tcg,thread=multi', '-cpu', 'cortex-a72',
    '-smp', '2', '-m', "$MemoryMB",
    '-bios', 'assets/u-boot.bin',
    '-drive', 'if=pflash,unit=1,format=raw,file=data/uboot-env.img',
    '-drive', 'if=none,id=os,file=data/session.qcow2,format=qcow2',
    '-device', 'virtio-blk-pci,drive=os',
    '-drive', 'if=none,id=boot,file=assets/boot.img,format=raw,readonly=on',
    '-device', 'virtio-blk-pci,drive=boot',
    '-netdev', 'user,id=net,hostfwd=tcp:127.0.0.1:2222-:22,hostfwd=tcp:127.0.0.1:8899-:8899',
    '-device', 'virtio-net-pci,netdev=net,romfile=,mac=52:54:00:12:34:56',
    '-netdev', 'user,id=lan,restrict=on,net=192.168.50.0/24,ipv6=off',
    '-device', 'virtio-net-pci,netdev=lan,romfile=,mac=52:54:00:12:34:57',
    '-device', 'virtio-gpu-pci,xres=1024,yres=600', '-device', 'virtio-keyboard-pci',
    '-device', 'virtio-mouse-pci', '-device', 'virtio-rng-pci',
    '-device', 'virtio-sound-pci',
    '-serial', 'mon:stdio'
)
& $qemu @qemuArgs
if ($LASTEXITCODE -ne 0) { throw 'QEMU stopped with an error. Check the console message above.' }
