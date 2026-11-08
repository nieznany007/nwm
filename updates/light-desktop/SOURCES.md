Pakiety ARM64 i all: oficjalne repozytoria Debian 13 trixie oraz trixie-security,
https://deb.debian.org/debian/ i https://deb.debian.org/debian-security/.
APT sprawdził podpisy indeksów i sumy pakietów. Dokładne wersje są w nazwach .deb
wewnątrz flipper-light-update.tar, sumy w PACKAGES.SHA256. Pakiety zachowują własne
pliki copyright i licencje w usr/share/doc wewnątrz .deb. Źródła upstream i źródła
pakietów Debian: https://sources.debian.org/ (wyszukaj nazwę i wersję pakietu).
Skrypty aktualizatora i konfiguracja: MIT, jak adapter w repozytorium projektu.

Moduł evdev.ko: Debian linux-image-6.12.115+deb13.1-arm64, wersja 6.12.115-2,
zgodny z kernelem adaptera 0.2. GPL-2.0, źródła:
https://sources.debian.org/src/linux/6.12.115-2/ . Suma w MODULES.SHA256.
