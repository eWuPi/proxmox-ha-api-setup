# Proxmox VE – Home Assistant Integration Helper

Automatyczny skrypt w języku Bash konfigurujący dedykowaną rolę, użytkownika, uprawnienia ACL oraz token API w **Proxmox VE** na potrzeby integracji z **Home Assistant**.

## 🚀 Funkcje skryptu

- **Idempotentność:** Skrypt można uruchamiać wielokrotnie – automatycznie sprawdza obecność roli i użytkownika, unikając błędów dublowania wpisów.
- **Bezpieczeństwo:** Tworzy dedykowaną rolę `HA-Monitor` z minimalnymi wymaganymi uprawnieniami (odczyt stanu, tworzenie migawek, zarządzanie zasilaniem VM/LXC).
- **Tryb `--privsep 0`:** Generuje token bez separacji uprawnień, co eliminuję problemy z brakiem dostępu do encji w Home Assistant.
- **Automatyczne pobieranie IP:** Skrypt wykrywa adres IP serwera Proxmox i wyświetla go w podsumowaniu.
- **Regeneracja tokena:** Jeśli token już istniał, skrypt go bezpiecznie usunie i wygeneruje nowy klucz `Secret` (ponieważ Proxmox pozwala na podgląd Secretu tylko raz).
- **Czytelna instrukcja:** Na końcu działania wyświetla dokładnie przygotowane dane do wklejenia w formularzu konfiguracji Home Assistanta.

---

## 🛠️ Wymagania

- Uprawnienia `root` na serwerze Proxmox VE (uruchomienie z poziomu konsoli SSH lub Shella w interfejsie www).

---

## 📥 Szybkie uruchomienie

Pobierz i uruchom skrypt bezpośrednio na węźle Proxmox VE:

```bash
curl -sSL [https://raw.githubusercontent.com/TWOJ_NICK/proxmox-ha-api-setup/main/setup-proxmox-ha.sh](https://raw.githubusercontent.com/TWOJ_NICK/proxmox-ha-api-setup/main/setup-proxmox-ha.sh) | bash
