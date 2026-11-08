# Weryfikacja wersji 0.2 — 2026-11-08

Testy wykonano na Debianie 13 x86_64, QEMU 10.0.13, virt ARM64 Cortex-A72,
2 vCPU i 1,5–2 GiB RAM. Emulacja programowa TCG.

## Potwierdzone

- Zgodność SHA256 oficjalnego archiwum builda 2485 z manifestem.
- Rozruch przez U-Boot i dysk FAT; menu pięciu oryginalnych profili.
- Trwałość środowiska U-Boota: saveenv, zamknięcie procesu QEMU i odczyt
  zmiennej w następnym procesie z tym samym plikiem flash.
- Minimal: pełny start z końcowym initramfs, logowanie, SSH, sieć i panel flipctl.
  Prawidłowe FSROOT dla /, /home, /boot, /var/log i /var/cache; zero nieudanych
  jednostek systemd, następnie poprawne zamknięcie systemu.
- Desktop: rzeczywisty pulpit KDE Plasma X11 z tapetą Flippera i paskiem zadań;
  uruchomione okno Konsole. Dopasowany kwin-x11 instaluje się offline.
  Kolejny pełny restart: ponownie widoczna tapeta i panel Plasma, po wybudzeniu
  wygaszonego monitora klawiszem Shift.
- Router, No-Graphics i TV-Media-Box: osobne rozruchy oryginalnych subwolumenów,
  logowanie, obecność 20 aplikacji we współdzielonym katalogu i zamknięcie systemu.
- Router i No-Graphics: brak nieudanych jednostek systemd w wykonanych testach.
- Hello World: widoczny tytuł „Hello, Flipper One!” przed i po Enter oraz zmiana
  obszaru licznika; kontrola OCR i pikseli w Chromium/Playwright.
  Weryfikacja po rozgrzaniu procesu aplikacji.
- Kolejka wejścia: test z opóźnioną odpowiedzią HTTP potwierdza kolejność key-down/key-up.
  Działający serwer podaje poprawiony JavaScript; Chromium potwierdza kolejność
  request-down, response-down, request-up, response-up i brak błędów JavaScript.
- Panel: przesyłany ekran, otwarcie menu klawiszem X, brak błędów JavaScript.
- Wszystkie 20 plików oficjalnego katalogu: zgodność rozmiaru i SHA256;
  initramfs ponawia kontrolę przed instalacją do @home.
- Regresja fstab: zachowanie sześciu pól i subwolumenów Btrfs, ponowny rozruch
  bez dublowania opcji oraz naprawa błędnego wpisu z wcześniejszego szkicu.
- Składnia PowerShell: parsowanie tree-sitter bez błędów.

## Ograniczenia

- Nie wykonano uruchomienia na Windows 10/11; testy QEMU odbyły się na Linuksie.
- Pierwszy start KDE pod TCG bywa bardzo wolny. Równoczesne uruchamianie aplikacji
  może przekroczyć limit pierwszej klatki flipctl (10 s); ponowne wybranie działającej
  już aplikacji pozwala wyświetlić ją po zakończeniu inicjalizacji.
- Nie sprawdzono każdej funkcji wszystkich 20 aplikacji. Wcześniejsze próby
  części aplikacji JavaScript przekraczały limit pierwszej klatki flipctl.
- Test TV wykazał błąd NetworkManager-wait-online przy wcześniejszej konfiguracji
  pustej sieci LAN. Finalna konfiguracja używa izolowanego backendu user i ignoruje
  end1 poza Routerem; osobny pełny test TV z tą zmianą nie został powtórzony.
- Nie zweryfikowano odtwarzania mediów, dźwięku, udziałów SMB ani routowania ruchu.
- Zmiana profilu przez panel, kexec, aktualizacje kernela, klonowanie i factory reset
  nie mają potwierdzonej zgodności. Profile wybiera się w menu U-Boota.
- Internet gościa w chmurze podlegał ograniczeniom proxy; aplikacje są dołączone offline.
- RK3576, MCU, RF, modem i pozostała fizyczna elektronika nie są emulowane.

To adapter oryginalnego systemu do QEMU, a nie pełna emulacja sprzętu Flipper One.
