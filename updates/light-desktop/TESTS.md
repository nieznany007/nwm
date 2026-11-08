# Testy aktualizacji 0.3 — 2026-11-08

QEMU 10.0.13 na Linuksie x86_64, emulacja ARM64 TCG, Cortex-A72,
2 vCPU, 2 GiB RAM; oryginalny profil @Desktop z paczki 0.2.

Potwierdzone:

- Instalacja 35 pakietów offline, zgodne SHA256, dpkg --audit bez błędów.
- Przełącznik zapisuje zarówno plasmax11.desktop, jak i flipper-light.desktop.
- Pełne restarty uruchamiają Openbox i tint2 w @Desktop; Plasma i KWin nie działają.
- Kolejny pełny restart automatycznie ładuje evdev i udostępnia event0 oraz event1.
- Wpisanie uname -m przez emulowaną klawiaturę w XTerm wyświetla aarch64.
- Widoczne okna XTerm i PCManFM, pasek tint2 i menedżer okien Openbox.
- Systemd: zero nieudanych jednostek w obu próbach lekkiego pulpitu.
- Próbki free -m: przed instalacją podczas działania KDE used=1062 MiB;
  lekki pulpit po rozruchu used=242 MiB i w powtórnej próbie 241 MiB.
  To próbki tej samej VM, nie standaryzowany benchmark FPS ani wynik na Windows.
- Składnia aktualizatora PowerShell sprawdzona parserem tree-sitter.

Ograniczenia:

- Aktualizatora nie uruchamiano na rzeczywistym Windows 10/11.
- Nie zmierzono FPS i nie przetestowano każdej aplikacji Flippera w nowej sesji.
- QEMU nadal programowo emuluje ARM64; lżejszy pulpit nie usuwa tego narzutu.
- Powrót do KDE sprawdzono na poziomie konfiguracji; po aktualizacji uruchamiano
  ponownie tryb lekki. KDE działało w tym samym obrazie przed aktualizacją.
