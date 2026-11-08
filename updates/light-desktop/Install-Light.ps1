param([int]$SshPort = 2222)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$ssh = (Get-Command ssh.exe -ErrorAction Stop).Source
$scp = (Get-Command scp.exe -ErrorAction Stop).Source
$archive = Join-Path $PSScriptRoot 'flipper-light-update.tar'
$expected = '7e70f6814687c59ef5a10ab558a0021a2be7c936e7232092899a73c11fd116d6'
if ((Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash.ToLowerInvariant() -ne $expected) {
    throw 'Update checksum mismatch. Download the update again.'
}
Write-Host 'Start the existing emulator and choose Desktop (1). Wait for SSH to become available.'
Write-Host 'Save your work inside Linux. Linux will reboot after installation.'
Write-Host 'SSH login: user. Password: user (unless you changed it).'
Read-Host 'Press ENTER when the emulator is ready' | Out-Null
$options = @('-o', 'StrictHostKeyChecking=accept-new', '-o', 'ConnectTimeout=20')
& $scp @options -P "$SshPort" $archive 'user@127.0.0.1:flipper-light-update.tar'
if ($LASTEXITCODE -ne 0) { throw 'Copy failed. Keep the emulator running and check the SSH password.' }
$command = 'mkdir -p "$HOME/flipper-light-update" && tar -xf "$HOME/flipper-light-update.tar" -C "$HOME/flipper-light-update" && sudo sh "$HOME/flipper-light-update/install-light.sh" && sudo systemctl reboot --no-block'
& $ssh @options -p "$SshPort" 'user@127.0.0.1' $command
if ($LASTEXITCODE -ne 0) { throw 'Installation failed. Check the Linux messages above.' }
Write-Host 'Installed. During reboot choose Desktop (1). It now starts Flipper Light.'
Write-Host 'The Flipper panel remains at http://127.0.0.1:8899/'
