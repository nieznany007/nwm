# Flipper Light — aktualizacja do paczki QEMU 0.2

Wersja 0.3. Aktualizacja naprawia także brak modułu evdev w paczce 0.2 —
moduł jest potrzebny do działania klawiatury i myszy w X11. Wymaga kernela
6.12.115+deb13.1-arm64 dostarczonego z paczką 0.2.

To opcjonalny lekki pulpit: Openbox, tint2, XTerm i PCManFM. Nie emuluje natywnie
ARM64 i nie usuwa narzutu QEMU, ale pomija ciężkie komponenty KDE Plasma.
Oryginalne profile, aplikacje i obraz bazowy pozostają dostępne.

## Instalacja na Windows 10/11

1. Rozpakuj całą aktualizację do zapisywalnego folderu.
2. Uruchom dotychczasową paczkę emulatora: Start.cmd, profil Desktop (1).
   Pozostaw ją uruchomioną podczas instalacji; poczekaj na napis login: w konsoli.
3. Zapisz pracę w Linuksie. Instalacja zakończy się restartem Linuksa.
4. Uruchom Install-Light.cmd i naciśnij Enter, gdy emulator udostępnia SSH.
5. Przy pytaniach SSH wpisuj hasło użytkownika `user` — domyślnie także `user`.
   Hasło może być potrzebne osobno do kopiowania i instalacji.
6. Po restarcie wybierz Desktop (1). Teraz uruchomi się lekki pulpit.

Aktualizacja sprawdza SHA256 archiwum oraz wszystkich 35 pakietów. Internet w gościu
nie jest potrzebny. Wymagane są ssh.exe i scp.exe z klienta OpenSSH dla Windows;
jeśli Windows ich nie ma, dodaj funkcję opcjonalną „Klient OpenSSH”.
Nie uruchamiaj dwóch emulatorów jednocześnie na porcie SSH 2222.

Panel urządzenia otwieraj w przeglądarce Windows: http://127.0.0.1:8899/.
Na lekkim pulpicie prawy przycisk myszy otwiera menu Terminal / Files / Power off;
ikony na dolnym pasku uruchamiają terminal i menedżer plików. Alt+Tab zmienia okno.

## Przywrócenie KDE

Połącz się z Windows: `ssh -p 2222 user@127.0.0.1`, a następnie wykonaj:

```
sudo flipper-desktop-mode kde
sudo reboot
```

Powrót do lekkiego pulpitu: `sudo flipper-desktop-mode light`, następnie `sudo reboot`.
Nie kasuj pliku session.qcow2 — tam zapisuje się ta aktualizacja i Twoje dane.

QEMU nadal programowo emuluje ARM64; nie jest to gwarancja płynności każdej aplikacji.

Test rozruchu i aplikacji wykonano w QEMU na Linuksie (2 vCPU, 2 GiB RAM).
Składnia aktualizatora PowerShell została sprawdzona; nie uruchamiano go na Windows.
