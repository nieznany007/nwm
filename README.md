# Flipper One w QEMU — Windows 10/11

Wersja eksperymentalna 0.2. Testy QEMU wykonano na Linuksie; launcher Windows
nie został przetestowany na rzeczywistym Windows.

Gotowy pakiet znajduje się w sekcji **Releases**, jako `flipper-one-windows-v0.2.zip`.
Rozpakuj całość i uruchom `Start.cmd`; QEMU dla Windows trzeba zainstalować osobno.
Pierwszy start pobierze oficjalny obraz Flipper One build 2485 (~2 GB).

**Code → Download ZIP zawiera źródła i dokumentację, bez binarnych składników
pakietu startowego. Do uruchomienia pobierz ZIP z Releases.**

Nie jest to pełna emulacja elektroniki. Oryginalny system plików i profile działają
z U-Bootem i kernelem dla QEMU virt. Radio, MCU i bootloader RK3576 nie są emulowane.

Instrukcja: [README-PL.md](README-PL.md). Zakres testów: [TESTS.md](TESTS.md).
Pochodzenie i licencje: [sources/PROVENANCE.md](sources/PROVENANCE.md).

SHA256 gotowego ZIP-a:
`6ff23dd736ccc88ce16b2910bc636e6b680797b78a82c1ab67e14b19eb453d09`
