#!/bin/sh
set -eu
[ "$(id -u)" = 0 ] || { echo 'Run this installer with sudo.'; exit 1; }
if [ ! -x /usr/bin/flipctl ] || [ "$(findmnt -rn -o FSROOT /)" != /@Desktop ]; then
    echo 'Start the Flipper One Desktop profile (1) before installing this update.'
    exit 1
fi
cd "$(dirname "$0")"
if [ "$(uname -r)" != 6.12.115+deb13.1-arm64 ]; then
    echo "This update requires the QEMU kernel from package 0.2 (6.12.115+deb13.1-arm64)."; exit 1
fi
sha256sum -c MODULES.SHA256
sha256sum -c PACKAGES.SHA256
dpkg -i packages/*.deb
sh ./configure-light.sh
