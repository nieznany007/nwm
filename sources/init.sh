#!/bin/sh
export PATH=/bin:/sbin:/usr/bin:/usr/sbin
mount -t proc proc /proc
mount -t sysfs sysfs /sys
mount -t devtmpfs devtmpfs /dev
echo 'Flipper One: QEMU adaptation initramfs'
. /load-modules.sh
profile=Minimal
for arg in $(cat /proc/cmdline); do
    case "$arg" in flipper.profile=*) profile=${arg#*=};; esac
done
case "$profile" in Minimal|Desktop|Router|TV-Media-Box|No-Graphics) ;; *) echo 'Invalid profile'; exec sh;; esac
for attempt in 1 2 3 4 5; do
    [ -b /dev/vda3 ] && break
    sleep 1
done
echo "Mounting original Flipper OS profile @$profile from /dev/vda3"
mount -t btrfs -o "rw,subvol=@$profile,compress=zstd:1,noatime" /dev/vda3 /newroot || exec sh
if [ -b /dev/vdb1 ]; then
    mkdir -p /apps-media /home-store
    if mount -t vfat -o ro /dev/vdb1 /apps-media; then
        if [ -d /apps-media/Apps ] && mount -t btrfs -o rw,subvol=@home /dev/vda3 /home-store; then
            if [ ! -e /home-store/user/.qemu-bundled-apps-2485 ]; then
                echo 'Installing verified official catalogue apps into shared home...'
                if (cd /apps-media/Apps && sha256sum -c /apps-media/APPS.SHA256); then
                    mkdir -p /home-store/user/Apps
                    if cp -r /apps-media/Apps/. /home-store/user/Apps/; then
                        chown -R 1000:1000 /home-store/user/Apps
                        find /home-store/user/Apps -type f -name '*.AppImage' -exec chmod a+x '{}' ';'
                        touch /home-store/user/.qemu-bundled-apps-2485
                    fi
                else
                    echo 'App checksum verification failed; apps were not installed.'
                fi
            fi
            umount /home-store
        fi
        if [ "$profile" = Desktop ] && [ -f /apps-media/DesktopPkgs/kwin-x11.deb ]; then
            kwin_status=$(chroot /newroot /usr/bin/dpkg-query -W -f='${Status}' kwin-x11 2>/dev/null)
            if [ "$kwin_status" != 'install ok installed' ]; then
                if (cd /apps-media && sha256sum -c DESKTOP.SHA256); then
                    mkdir -p /newroot/var/cache/flipper-qemu
                    cp /apps-media/DesktopPkgs/kwin-x11.deb /newroot/var/cache/flipper-qemu/kwin-x11.deb
                    echo 'Installing the matching official Flipper KWin X11 package...'
                    mount --bind /dev /newroot/dev
                    mount --bind /proc /newroot/proc
                    mount --bind /sys /newroot/sys
                    chroot /newroot /usr/bin/env DEBIAN_FRONTEND=noninteractive /usr/bin/dpkg -i /var/cache/flipper-qemu/kwin-x11.deb || echo 'KWin X11 package configuration failed; see dpkg output above.'
                    umount /newroot/sys
                    umount /newroot/proc
                    umount /newroot/dev
                else
                    echo 'Desktop package checksum failed; KWin was not installed.'
                fi
            fi
        fi
        umount /apps-media
    fi
fi
# The bundled remote JavaScript is embedded in flipctl's ELF, not an asset file.
chroot /newroot /usr/bin/python3 - <<'QEMU_REMOTE_PATCH'
#!/usr/bin/env python3
"""Patch embedded browser input ordering without changing ELF offsets."""
from pathlib import Path
import os,shutil,sys
p=Path(sys.argv[1] if len(sys.argv)>1 else '/usr/bin/flipctl')
data=p.read_bytes();marker=b'QEMU_INPUT_QUEUE_V1'
if marker in data:
 print('Remote input queue already installed');sys.exit(0)
start=b'/// Post one key event. The same endpoint the panel\'s own buttons feed.\n'
end=b'/// Wire a set of buttons carrying'
a=data.find(start)
if a<0 or data.count(start)!=1:raise SystemExit('Unrecognized flipctl; input patch skipped')
b=data.find(end,a)
if b<0 or b-a>2048:raise SystemExit('Unrecognized remote input block')
new=b'''//QEMU_INPUT_QUEUE_V1
let q=Promise.resolve();function flipperSend(key,down){return q=q.then(()=>fetch('input',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({key,down})})).catch(()=>{});}
'''
if len(new)>b-a:raise SystemExit('Input patch exceeds original block')
patched=data[:a]+new+b' '*(b-a-len(new))+data[b:]
assert len(patched)==len(data)
tmp=p.with_name(p.name+'.qemu-input.tmp');shutil.copy2(p,tmp);tmp.write_bytes(patched);os.replace(tmp,p)
print('Installed ordered browser input; ELF size and offsets preserved')
QEMU_REMOTE_PATCH
mkdir -p /newroot/usr/lib/modules
cp -a /lib/modules/* /newroot/usr/lib/modules/
mkdir -p /newroot/etc/systemd/network
cat > /newroot/etc/systemd/network/10-qemu-wan.link <<'EOF'
[Match]
MACAddress=52:54:00:12:34:56
[Link]
Name=end0
EOF
cat > /newroot/etc/systemd/network/10-qemu-lan.link <<'EOF'
[Match]
MACAddress=52:54:00:12:34:57
[Link]
Name=end1
EOF
if [ "$profile" != Router ]; then
    mkdir -p /newroot/etc/NetworkManager/conf.d
    cat > /newroot/etc/NetworkManager/conf.d/99-qemu-lan.conf <<'EOF'
[keyfile]
unmanaged-devices=interface-name:end1
EOF
fi
mount -t tmpfs tmpfs /newroot/run
mkdir -p /newroot/run/systemd/system/flipctl.service.d
cat > /newroot/run/systemd/system/flipctl.service.d/90-qemu.conf <<'EOF'
[Service]
ExecStart=
ExecStart=/usr/bin/flipctl --headless --remote 0.0.0.0:8899 --assets /usr/share/flipctl/assets/remote
Environment=XDG_SEAT=
Environment=XDG_SESSION_TYPE=unspecified
Environment=XDG_SESSION_CLASS=background
Environment=WLR_RENDERER=pixman
Environment=FLIPCTL_NO_GPU=1
Environment=FLIPCTL_APP_HZ=15
Environment=LIBGL_ALWAYS_SOFTWARE=1
Environment=GALLIUM_DRIVER=softpipe
DeviceAllow=block-virtblk rw
DeviceAllow=/dev/dri/card0 rw
EOF
if [ "$profile" = Desktop ]; then
    mkdir -p /newroot/etc/sddm.conf.d /newroot/etc/X11/xorg.conf.d
    cat > /newroot/etc/sddm.conf <<'EOF'
[General]
DisplayServer=x11
[Autologin]
User=user
Session=plasmax11.desktop
EOF
    cat > /newroot/etc/X11/xorg.conf.d/90-qemu.conf <<'EOF'
Section "Device"
 Identifier "QEMU VirtIO"
 Driver "modesetting"
 Option "AccelMethod" "none"
EndSection
EOF
    mkdir -p /home-store
    if mount -t btrfs -o rw,subvol=@home /dev/vda3 /home-store; then
        mkdir -p /home-store/user/.config/plasma-workspace/env
        chown 1000:1000 /home-store/user/.config
        cat > /home-store/user/.config/plasma-workspace/env/qemu.sh <<'EOF'
export QT_QUICK_BACKEND=software
export LIBGL_ALWAYS_SOFTWARE=1
export GALLIUM_DRIVER=softpipe
export KWIN_COMPOSE=N
EOF
        cat > /home-store/user/.config/ksplashrc <<'EOF'
[KSplash]
Engine=KSplashQML
Theme=org.kde.breeze.desktop
EOF
        cat > /home-store/user/.config/baloofilerc <<'EOF'
[Basic Settings]
Indexing-Enabled=false
EOF
        cat > /home-store/user/.config/startkderc <<'EOF'
[General]
systemdBoot=false
EOF
        chown -R 1000:1000 /home-store/user/.config/plasma-workspace
        chown 1000:1000 /home-store/user/.config/ksplashrc /home-store/user/.config/baloofilerc
        chown 1000:1000 /home-store/user/.config/startkderc
        umount /home-store
    fi
fi
if [ "$profile" = TV-Media-Box ]; then
    mkdir -p /newroot/run/systemd/system/kodi.service.d
    cat > /newroot/run/systemd/system/kodi.service.d/90-qemu.conf <<'EOF'
[Service]
ExecStartPre=
Environment=WLR_RENDERER=pixman
Environment=LIBGL_ALWAYS_SOFTWARE=1
Environment=GALLIUM_DRIVER=softpipe
EOF
fi
echo 'Official profiles present:'
mkdir -p /top
mount -t btrfs -o ro,subvolid=5 /dev/vda3 /top
ls /top
umount /top
echo 'Switching to original systemd. QEMU adaptation active.'
mount --move /proc /newroot/proc
mount --move /sys /newroot/sys
mount --move /dev /newroot/dev
# Seed block/console udev records before PID 1 starts its mount jobs. Under TCG,
# coldplugging the whole board can otherwise exhaust fstab's 90 second timer.
awk '
$3 == "btrfs" {
    if (NF == 7 && $4 ~ /^,x-systemd.device-timeout=/) {
        timeout = $4; sub(/^,/, "", timeout)
        $4 = $5 "," timeout; $5 = $6; $6 = $7; NF = 6
    }
    if ($4 !~ /x-systemd.device-timeout=/) $4 = $4 ",x-systemd.device-timeout=300s"
}
{ print }
' /newroot/etc/fstab > /newroot/etc/fstab.qemu.tmp
mv /newroot/etc/fstab.qemu.tmp /newroot/etc/fstab
echo 'Preparing disk and serial-console device records...'
cat > /newroot/run/qemu-early.sh <<'EOF'
#!/bin/sh
export PATH=/usr/sbin:/usr/bin:/sbin:/bin
if /usr/lib/systemd/systemd-udevd --daemon; then
    /usr/bin/udevadm trigger --action=add --subsystem-match=block
    /usr/bin/udevadm trigger --action=add --subsystem-match=tty --sysname-match=ttyAMA0
    /usr/bin/udevadm settle --timeout=180 || echo 'udev settle timed out; systemd will continue coldplug.'
    /usr/bin/udevadm control --exit
fi
exec /sbin/init
EOF
# Run the second stage after switch_root: udevadm intentionally ignores requests
# from chroots, even when they point at the intended root filesystem.
exec switch_root /newroot /bin/sh /run/qemu-early.sh
