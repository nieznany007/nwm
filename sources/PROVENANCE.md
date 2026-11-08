# Pochodzenie

Oficjalny obraz Flipper One 2485 i jego manifest:
https://dl-linux-images.flipp.dev/full-img/2485/

Oficjalne skrypty budowania obrazu, commit z manifestu:
https://github.com/flipperdevices/flipperone-linux-build-scripts/tree/d21ab22ac67f02c2e817d2b6e7b99d2cc615bd90

Kod flipctl z manifestu:
https://github.com/flipperdevices/flipctl-slint/tree/99d8ef816a190026a9ff8eec95f86fa95228d238

Aplikacje: oficjalny katalog i binaria release `apps`:
https://github.com/flipperdevices/flipctl-apps
https://github.com/flipperdevices/flipctl-apps/releases/tag/apps
Źródła aplikacji i informacje licencyjne:
https://github.com/flipperdevices/flipctl-slint/tree/99d8ef816a190026a9ff8eec95f86fa95228d238/apps
Katalog aplikacji jest niezależną migawką z 2026-11-08; nie jest częścią pliku zst.

Kernel: pakiet Debian `linux-image-6.12.115+deb13.1-arm64`, wersja `6.12.115-2`.
Źródło Debian: https://sources.debian.org/src/linux/6.12.115-2/
GPL-2.0; konfiguracja znajduje się w `kernel.config`.

U-Boot: pakiet Debian `u-boot-qemu`, wersja `2025.01-3+deb13u1`, qemu_arm64.
Źródło Debian: https://sources.debian.org/src/u-boot/2025.01-3+deb13u1/
GPL-2.0+.

BusyBox w initramfs: pakiet Debian `busybox-static:arm64`, wersja `1:1.37.0-6+b9`.
Źródło Debian: https://sources.debian.org/src/busybox/1:1.37.0-6/
GPL-2.0.

zstd.exe: oficjalny zstd 1.5.7 Windows x64:
https://github.com/meta/zstd/releases/tag/v1.5.7
Źródła: https://github.com/meta/zstd/tree/v1.5.7
Dual BSD-3-Clause / GPL-2.0; w pakiecie zachowano tekst licencji BSD.

Skrypty adaptera i launchera napisane dla tego projektu: MIT, tekst w ADAPTER-LICENSE.
`build_initramfs.py` oczekuje rozpakowanych pakietów Debian w katalogach
`kernel`, `busybox`, `tools` obok skryptu. Zachowuje moduły kernelowe potrzebne
QEMU, ich zależności i metadane depmod. `init.sh` jest PID 1 initramfs, po czym
przekazuje sterowanie oryginalnemu systemd z wybranego subwolumenu Btrfs.


KWin X11: oficjalne repozytorium Flipper One, dopasowane do bibliotek obrazu:
https://dl-linux-images.flipp.dev/flipperone-deb/pool/main/k/kwin/kwin-x11_6.3.6-1+deb13u1+flipper1_arm64.deb
Rozmiar: 415256 bajtów.
SHA256: 688b1159374a00a330db1cfd62aac63a9ea1871c411e107cc5f651ab0fc082e8
Pakiet zachowany wewnątrz assets/boot.img, katalog DesktopPkgs. Zawiera informacje
licencyjne upstream; kontrola integralności w sources/DESKTOP.SHA256.

Zmiana flipctl w warstwie emulatora: skrypt patch_remote_input.py podmienia wyłącznie
fragment osadzonego remote.js odpowiedzialny za kolejność żądań klawiatury.
Zachowuje rozmiar pliku ELF i wszystkie offsety; ma kontrolę rozpoznawanego bloku
i znacznik zapobiegający powtórnemu patchowaniu. Oryginalny obraz bazowy pozostaje
bez zmian; modyfikacja zapisuje się w qcow2. Kod poprawki i implementacja initramfs
są dołączone. Nie jest to niezmodyfikowana binarka upstream flipctl.
