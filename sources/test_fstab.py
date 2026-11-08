#!/usr/bin/env python3
"""Check that the adapter preserves Btrfs subvolumes across whitespace and upgrades."""
from pathlib import Path
import subprocess

root = Path(__file__).resolve().parent
source = (root / 'init.sh').read_text()
program = source.split("awk '\n$3 ==", 1)[1].split("' /newroot/etc/fstab", 1)[0]
program = '\n$3 ==' + program
fixture = '''# Original-style rows and a regression from the first adapter draft.
UUID=test / btrfs defaults 0 0
UUID=test\t/home\tbtrfs     compress=zstd:1,noatime,subvol=@home\t0\t0
UUID=test /var/log btrfs compress=zstd:1,subvol=@var-log,x-systemd.device-timeout=300s 0 0
UUID=test /boot btrfs ,x-systemd.device-timeout=300s compress=zstd:1,subvol=boot 0 0
'''

def run(text):
    return subprocess.run(['awk', program], input=text, text=True, capture_output=True, check=True).stdout

result = run(fixture)
assert run(result) == result, 'Repeated boots must not duplicate mount options'
rows = [line.split() for line in result.splitlines() if not line.startswith('#')]
assert all(len(row) == 6 for row in rows), result
assert all(row[4:] == ['0', '0'] for row in rows), result
assert all(row[3].count('x-systemd.device-timeout=300s') == 1 for row in rows)
by_mount = {row[1]: row[3] for row in rows}
assert 'subvol=@home' in by_mount['/home']
assert 'subvol=@var-log' in by_mount['/var/log']
assert 'subvol=boot' in by_mount['/boot']
assert 'defaults' in by_mount['/']
print('PASS: fstab fields, Btrfs subvolumes, repeated boots and old-draft repair')
