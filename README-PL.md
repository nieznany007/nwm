# Flipper One build 2485 w QEMU na Windows 10/11

To uruchomienie prawdziwego systemu ARM64 z oficjalnego obrazu, z adapterem do QEMU.
Nie jest to pełny emulator elektroniki Flipper One. RK3576 nie jest obsługiwany przez
użyte QEMU 10.0.13, dlatego kernel i U-Boot są wariantami dla maszyny `virt`.
System plików, profile i flipctl pochodzą z oryginalnego obrazu. Oryginalny bootloader
Rockchipa pozostaje w bazowym obrazie, ale nie jest wykonywany.

Wersja adaptera: 0.2 (2026-11-08).

## Start

1. Zainstaluj 64-bitowe QEMU dla Windows, najlepiej w wersji 10 lub nowszej:
   https://www.qemu.org/download/#windows
2. Rozpakuj cały pakiet do zapisywalnego folderu. Zostaw co najmniej 12 GB wolnego miejsca.
3. Uruchom `Start.cmd`. Przy pierwszym starcie pobierze około 2 GB, sprawdzi SHA256
   i rozpakuje bazowy dysk o rozmiarze 6 GiB. Wymagane jest połączenie z Internetem.
   Jeśli masz już oficjalny plik `.zst`, przeciągnij go na `Start.cmd`, aby uniknąć ponownego pobierania.
4. W konsoli pojawi się menu U-Boota. Wpisz numer i Enter:
   1 — Desktop, 2 — Minimal, 3 — Router, 4 — TV-Media-Box, 5 — No-Graphics.
   Po 10 sekundach uruchamia się Desktop.
5. Poczekaj na start Linuksa. Pierwszy start pod emulacją może potrwać 5–10 minut, a na wolniejszym komputerze dłużej.
   Poczekaj na pulpit przed otwieraniem aplikacji. Jeśli aplikacja przekroczy limit
   pierwszej klatki, po chwili wybierz ją ponownie z listy działających aplikacji.
   Jeśli okno QEMU pozostaje czarne po starcie, kliknij je i naciśnij Shift.
   Monitor może się wygasić podczas powolnego rozruchu; w teście przywróciło to pulpit.
6. Uruchom `Open-Panel.cmd`, aby otworzyć http://127.0.0.1:8899/.
   Mały panel urządzenia działa w przeglądarce; okno QEMU pełni rolę zewnętrznego monitora.

Jeśli QEMU jest w innym folderze, uruchom PowerShell w folderze pakietu:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Start-Flipper.ps1 -QemuDirectory 'D:\Programy\qemu'
```

Nie trzeba uruchamiać pakietu jako administrator. Zmiana ExecutionPolicy dotyczy
wyłącznie procesu uruchamiającego ten skrypt.

## Panel i konsola

Na stronie panelu włącz „Show controls”, żeby zobaczyć przyciski.
Na ekranie początkowym X otwiera Menu, a B uruchamia funkcję Desktop.
Strzałki przesuwają wybór, Enter zatwierdza, Backspace wraca, Tab przełącza aplikacje.
Pozostałe przyciski mają opisy na stronie.

Logowanie do Linuksa: `user`, hasło `user` — dane z oficjalnego obrazu.

```powershell
ssh -p 2222 user@127.0.0.1
```

Zamknij system poleceniem `sudo poweroff`. Aby zmienić profil z menu U-Boota,
zamknij system i uruchom `Start.cmd` ponownie.

## Aplikacje

Sam obraz 2485 nie zawiera aplikacji panelu. Do pakietu dodano 20 pozycji z oficjalnego
katalogu https://raw.githubusercontent.com/flipperdevices/flipctl-apps/dev/apps.toml,
w tym Hello World, Doom, Browser, System Monitor oraz runtime Python i JavaScript.
Każdy pobrany plik sprawdzono według rozmiaru i SHA256 z katalogu.
Lista i hashe są w `sources/apps.toml` oraz `sources/APPS.SHA256`.

Przy pierwszym starcie adapter sprawdza pliki ponownie i kopiuje je do współdzielonego
`/home/user/Apps`. Profile korzystają z tego samego katalogu domowego.
Instalacja aplikacji nie oznacza, że każda jej funkcja sprzętowa działa w emulatorze.
Kolejne aplikacje można instalować przez oficjalny App Manager, jeśli gość ma dostęp
do serwerów katalogu i GitHuba.

## Co zostało dostosowane

- U-Boot 2025.01 dla QEMU ARM64, z menu extlinux wybierającym pięć oryginalnych subwolumenów.
- Kernel Debian ARM64 6.12.115+deb13.1 oraz mały initramfs z modułami VirtIO i Btrfs.
- Panel przeglądarkowy kolejkuje zdarzenia klawiatury, aby puszczenie klawisza
  następowało po jego naciśnięciu także przy wolnym TCG.
- flipctl uruchamia się w oficjalnym trybie `--headless --remote`, bez fizycznego panelu SPI.
- Desktop uruchamia KDE Plasma przez X11 i renderowanie programowe. Brakujący KWin X11
  pochodzi z oficjalnego repozytorium Flippera, w wersji zgodnej z bibliotekami obrazu.
- TV-Media-Box otrzymuje ustawienia renderowania programowego i pomija wymóg fizycznego HDMI.
- Dwie karty VirtIO odpowiadają end0 (NAT) i end1 (izolowana sieć LAN).
- Osobny plik data/uboot-env.img zachowuje ustawienia U-Boota pomiędzy uruchomieniami.
- Parametry rozruchu maskują usługi fizycznego USB gadget i iwd, ponieważ ta maszyna
  nie udostępnia kontrolera USB urządzenia ani adaptera Wi-Fi.
- Warstwa `data/session.qcow2` przechowuje zmiany, bazowy dysk pozostaje niezmieniony.
- Przekierowania SSH i panelu są dostępne wyłącznie na lokalnym adresie 127.0.0.1.

Obraz oficjalny:
https://dl-linux-images.flipp.dev/full-img/2485/debian-512-flipper-one-2485.img.zst

SHA256 pliku zst:
`222b81f078ea96fe3e832f76e700fcdae3fd10b192b2b1e36c7d2e9749bb4154`

## Granice zgodności

Nie są emulowane RK3576, MCU RP2350, fizyczne radia, modem, czujniki baterii,
panel i przyciski SPI/I2C, NPU ani kontroler USB urządzenia. Router ma wirtualny Ethernet;
nie otrzymuje fizycznego Wi-Fi/AP. Bateria i temperatura mogą być nieznane.
U-Boot z oryginalnego pliku oraz oryginalne kernele Rockchipa nie uruchamiają się na `virt`.
Zmiana profilu z oficjalnego panelu, kexec, aktualizacje kernela, factory reset i klonowanie
profili nie są potwierdzone jako zgodne z tym adapterem. Do wyboru profilu służy menu U-Boota.
Nie wszystkie aplikacje i profile zostały przetestowane funkcjonalnie.

Pakiet przygotowano dla Windows; testy rozruchu wykonywano w QEMU na Linuksie.
Nie przeprowadzono uruchomienia launchera na prawdziwym Windows.

## Pliki

- `Start.cmd`, `Start-Flipper.ps1` — przygotowanie dysku i uruchomienie QEMU.
- `assets/boot.img` — kernel, initramfs, menu i sprawdzone aplikacje.
- `assets/u-boot.bin` — firmware QEMU.
- `tools/zstd.exe` — oficjalny zstd 1.5.7 dla Windows x64.
- `sources/` — źródła adaptera, manifesty, konfiguracja i informacje o pochodzeniu.
- `SHA256SUMS` — sumy składników pakietu sprawdzane przez launcher.
- `TESTS.md` — zakres wykonanej weryfikacji.

QEMU trzeba zainstalować osobno. Nie jest dołączony do tego pakietu.
