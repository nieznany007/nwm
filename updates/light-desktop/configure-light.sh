#!/bin/sh
set -eu
cd "$(dirname "$0")"
sha256sum -c MODULES.SHA256
install -d /usr/local/lib/flipper-qemu
install -m 644 evdev.ko /usr/local/lib/flipper-qemu/evdev.ko
install -d /etc/flipper-qemu /etc/xdg/flipper-light /usr/local/bin /usr/local/sbin /usr/share/xsessions /etc/systemd/system/sddm.service.d
cat > /usr/local/bin/flipper-light-session <<'EOF'
#!/bin/sh
export XDG_SESSION_TYPE=x11 XDG_CURRENT_DESKTOP=FlipperLight
export LIBGL_ALWAYS_SOFTWARE=1 GALLIUM_DRIVER=softpipe QT_QUICK_BACKEND=software
unset WAYLAND_DISPLAY
dbus-update-activation-environment --systemd DISPLAY XAUTHORITY XDG_SESSION_TYPE XDG_CURRENT_DESKTOP LIBGL_ALWAYS_SOFTWARE GALLIUM_DRIVER QT_QUICK_BACKEND || true
xset s off || true
xset -dpms || true
xsetroot -solid '#122033' || true
tint2 -c /etc/xdg/flipper-light/tint2rc &
exec openbox --config-file /etc/xdg/flipper-light/rc.xml
EOF
chmod 755 /usr/local/bin/flipper-light-session
cp /etc/xdg/openbox/rc.xml /etc/xdg/flipper-light/rc.xml
sed -i 's|<file>menu.xml</file>|<file>/etc/xdg/flipper-light/menu.xml</file>|' /etc/xdg/flipper-light/rc.xml
cat > /etc/xdg/flipper-light/menu.xml <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<openbox_menu xmlns="http://openbox.org/3.4/menu">
 <menu id="root-menu" label="Flipper One - Light">
  <item label="Terminal"><action name="Execute"><command>xterm -fa Monospace -fs 11</command></action></item>
  <item label="Files"><action name="Execute"><command>pcmanfm</command></action></item>
  <separator />
  <item label="Power off"><action name="Execute"><command>systemctl poweroff</command></action></item>
 </menu>
</openbox_menu>
EOF
cat > /etc/xdg/flipper-light/tint2rc <<'EOF'
# Flipper Light: small C/X11 panel, no compositor or desktop indexer.
panel_items = LTSC
panel_position = bottom center horizontal
panel_size = 100% 34
panel_padding = 6 3 4
panel_background_id = 0
panel_monitor = all
panel_layer = top
panel_dock = 0
wm_menu = 1
rounded = 0
background_color = #182a40 100
border_width = 0
launcher_padding = 2 0 4
launcher_icon_size = 24
launcher_item_app = /usr/share/applications/flipper-light-terminal.desktop
launcher_item_app = /usr/share/applications/flipper-light-files.desktop
taskbar_mode = single_desktop
task_icon = 1
task_text = 1
task_font = Sans 10
task_maximum_size = 180 30
task_padding = 4 0 4
systray_icon_size = 20
systray_padding = 3 0 3
time1_format = %H:%M
time1_font = Sans Bold 10
clock_padding = 5 0
mouse_left = toggle_iconify
mouse_middle = close
mouse_right = toggle
EOF
cat > /usr/share/applications/flipper-light-terminal.desktop <<'EOF'
[Desktop Entry]
Type=Application
Name=Terminal
Exec=xterm -fa Monospace -fs 11
Icon=utilities-terminal
Categories=System;TerminalEmulator;
EOF
cat > /usr/share/applications/flipper-light-files.desktop <<'EOF'
[Desktop Entry]
Type=Application
Name=Files
Exec=pcmanfm
Icon=system-file-manager
Categories=System;FileManager;
EOF
cat > /usr/share/xsessions/flipper-light.desktop <<'EOF'
[Desktop Entry]
Type=Application
Name=Flipper Light
Comment=Openbox and tint2 for QEMU software emulation
Exec=/usr/local/bin/flipper-light-session
TryExec=/usr/local/bin/flipper-light-session
DesktopNames=FlipperLight
EOF
cat > /usr/local/sbin/flipper-desktop-mode <<'EOF'
#!/bin/sh
set -eu
if [ ! -d /sys/module/evdev ]; then
    /sbin/insmod /usr/local/lib/flipper-qemu/evdev.ko
fi
mode=$(cat /etc/flipper-qemu/desktop-mode 2>/dev/null || echo light)
if [ "$#" -gt 0 ]; then mode=$1; fi
case "$mode" in
 light) session=flipper-light.desktop ;;
 kde) session=plasmax11.desktop ;;
 *) echo 'Usage: sudo flipper-desktop-mode light|kde'; exit 1 ;;
esac
printf '%s\n' "$mode" > /etc/flipper-qemu/desktop-mode
cat > /etc/sddm.conf <<CONF
[General]
DisplayServer=x11
[Autologin]
User=user
Session=$session
CONF
EOF
chmod 755 /usr/local/sbin/flipper-desktop-mode
cat > /etc/systemd/system/sddm.service.d/95-flipper-light.conf <<'EOF'
[Service]
ExecStartPre=/usr/local/sbin/flipper-desktop-mode
EOF
/usr/local/sbin/flipper-desktop-mode light
systemctl daemon-reload
echo 'Light desktop installed. Reboot Linux and choose Desktop (1) in U-Boot.'
echo 'Restore KDE later: sudo flipper-desktop-mode kde; sudo reboot'
