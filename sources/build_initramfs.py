#!/usr/bin/env python3
"""Build a small QEMU adapter initramfs without mounting the official image."""
import gzip
import lzma
import os
from pathlib import Path
import shutil
import stat
import subprocess

W = Path(__file__).resolve().parent
K = W / 'kernel/usr/lib/modules'
version = next(K.iterdir()).name
source = K / version
root = W / 'initramfs'
root.mkdir(exist_ok=True)
for d in ['bin', 'sbin', 'proc', 'sys', 'dev', 'run', 'newroot', 'etc', 'tmp', f'lib/modules/{version}']:
    (root / d).mkdir(parents=True, exist_ok=True)
shutil.copy2(W / 'busybox/usr/bin/busybox', root / 'bin/busybox')
for app in ['sh', 'mount', 'umount', 'mkdir', 'cat', 'echo', 'sleep', 'insmod', 'modprobe', 'cp', 'mv', 'awk', 'ln', 'ls', 'find', 'chown', 'chmod', 'touch', 'sha256sum', 'dmesg', 'switch_root', 'reboot', 'poweroff', 'sync', 'grep', 'sed', 'head', 'ip', 'udhcpc', 'chroot']:
    link = root / 'bin' / app
    if not link.exists():
        link.symlink_to('busybox')
if not (root / 'sbin/modprobe').exists():
    (root / 'sbin/modprobe').symlink_to('../bin/busybox')
deps = {}
for line in (source / 'modules.dep').read_text().splitlines():
    name, rest = line.split(':', 1)
    deps[name] = rest.split()
selected = []
def add(name):
    if name in selected:
        return
    for dependency in deps[name]:
        add(dependency)
    selected.append(name)
names = ['virtio_pci', 'virtio_mmio', 'virtio_blk', 'crc32c_generic', 'crc32c-arm64', 'btrfs', 'virtio_net', 'virtio-gpu', 'virtio_input', 'virtio-rng', 'virtio_balloon', 'fuse', '9p', '9pnet_virtio', 'ipv6', 'tun', 'loop', 'usbhid', 'xhci-pci', 'virtio_snd']
names += ['configfs', 'autofs4', 'binfmt_misc', 'dm_mod', 'rfkill', 'cfg80211', 'mac80211', 'af_packet', 'bridge', '8021q', 'veth', 'overlay', 'efivarfs', 'vfat', 'nls_cp437', 'nls_ascii', 'nls_iso8859-1', 'nls_utf8']
for name in names:
    matches = [p for p in deps if Path(p).name.split('.ko')[0].replace('-', '_') == name.replace('-', '_')]
    for p in matches:
        add(p)
for p in deps:
    if '/netfilter/' in p:
        add(p)
outmods = root / 'lib/modules' / version
for p in selected:
    target = outmods / p.removesuffix('.xz')
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_bytes(lzma.decompress((source / p).read_bytes()) if p.endswith('.xz') else (source / p).read_bytes())
(outmods / 'modules.dep').write_text('\n'.join(p.removesuffix('.xz') + ': ' + ' '.join(d.removesuffix('.xz') for d in deps[p]) for p in selected) + '\n')
for name in ['modules.builtin', 'modules.builtin.modinfo', 'modules.order']:
    if (source / name).exists():
        shutil.copy2(source / name, outmods / name)
for name in ['modules.alias', 'modules.softdep']:
    shutil.copy2(source / name, outmods / name)
env = os.environ.copy()
env['LD_LIBRARY_PATH'] = str(W / 'tools/usr/lib/x86_64-linux-gnu')
subprocess.run([str(W / 'tools/usr/sbin/depmod'), '-b', str(root), version], check=True, env=env)
(root / 'load-modules.sh').write_text('\n'.join('insmod /lib/modules/' + version + '/' + p.removesuffix('.xz') + ' || true' for p in selected if '/netfilter/' not in p) + '\n')
shutil.copy2(W / 'init.sh', root / 'init')
(root / 'init').chmod(0o755)

def pack():
    ino = 1
    for p in sorted(root.rglob('*')):
        s = p.lstat()
        name = str(p.relative_to(root)).encode() + b'\0'
        data = os.readlink(p).encode() if p.is_symlink() else p.read_bytes() if p.is_file() else b''
        values = [ino, s.st_mode, 0, 0, 1, 0, len(data), 0, 0, 0, 0, len(name), 0]
        header = b'070701' + b''.join(f'{v:08x}'.encode() for v in values)
        yield header + name + b'\0' * (-(110 + len(name)) % 4)
        yield data + b'\0' * (-len(data) % 4)
        ino += 1
    name = b'TRAILER!!!\0'
    values = [0] * 13
    values[11] = len(name)
    yield b'070701' + b''.join(f'{v:08x}'.encode() for v in values) + name + b'\0' * (-(110 + len(name)) % 4)
with gzip.open(W / 'initramfs.cpio.gz', 'wb', compresslevel=3) as f:
    for chunk in pack():
        f.write(chunk)
print(f'Built {version}: {len(selected)} modules, {(W / "initramfs.cpio.gz").stat().st_size} bytes')
