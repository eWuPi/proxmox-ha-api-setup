#!/bin/bash

# ==============================================================================
# SKRYPT AUTOMATYZUJĄCY KONFIGURACJĘ UŻYTKOWNIKA I TOKENA PROXMOX VE DLA HOME ASSISTANT
# ==============================================================================

set -e

# Wyłączenie rozwijania historii wykrzyknika w bashu dla bezpieczeństwa
set +o histexpand 2>/dev/null || true

# Pobranie głównego adresu IP serwera Proxmox VE
PROXMOX_IP=$(hostname -I | awk '{print $1}')

# Definicja zmiennych
USERNAME="homeassistant"
REALM="pve"
TOKEN_NAME="ha-token"
FULL_USER="${USERNAME}@${REALM}"
FULL_TOKEN="${FULL_USER}"'!'${TOKEN_NAME}
ROLE_NAME="HA-Monitor"
PRIVS="Sys.Audit Sys.Console Datastore.Audit VM.Audit VM.PowerMgmt VM.GuestAgent.Audit VM.Snapshot VM.Console"

echo "================================================================="
echo " Start konfiguracji Proxmox VE dla integracji Home Assistant"
echo "================================================================="

# ------------------------------------------------------------------------------
# 1. Tworzenie / Weryfikacja roli
# ------------------------------------------------------------------------------
echo "[1/4] Weryfikacja roli '${ROLE_NAME}'..."
if pveum role list | grep -qw "${ROLE_NAME}"; then
    echo " -> Rola '${ROLE_NAME}' już istnieje. Pomijanie..."
else
    echo " -> Tworzenie roli '${ROLE_NAME}'..."
    pveum role add "${ROLE_NAME}" -privs "${PRIVS}"
    echo " -> Rola została utworzona."
fi

# ------------------------------------------------------------------------------
# 2. Tworzenie / Weryfikacja użytkownika
# ------------------------------------------------------------------------------
echo "[2/4] Weryfikacja użytkownika '${FULL_USER}'..."
if pveum user list | grep -qw "${FULL_USER}"; then
    echo " -> Użytkownik '${FULL_USER}' już istnieje. Pomijanie..."
else
    echo " -> Tworzenie użytkownika '${FULL_USER}'..."
    pveum user add "${FULL_USER}" -comment "Użytkownik dla integracji Home Assistant"
    echo " -> Użytkownik został utworzony."
fi

# ------------------------------------------------------------------------------
# 3. Przypisanie uprawnień ACL na ścieżce głównej '/' dla UŻYTKOWNIKA
# ------------------------------------------------------------------------------
echo "[3/4] Weryfikacja uprawnień ACL na ścieżce '/' dla użytkownika..."
if pveum acl list | grep -E "\suser\s+${FULL_USER}\s" | grep -q "${ROLE_NAME}" 2>/dev/null; then
    echo " -> Użytkownik '${FULL_USER}' posiada już wymagane role na ścieżce '/'. Pomijanie..."
else
    echo " -> Nadawanie ról '${ROLE_NAME}' oraz 'PVEAdmin' dla użytkownika..."
    pveum acl modify / -user "${FULL_USER}" -roles "${ROLE_NAME},PVEAdmin"
fi

# ------------------------------------------------------------------------------
# 4. Regeneracja tokena API (Usunięcie starego i utworzenie nowego)
# ------------------------------------------------------------------------------
echo "[4/4] Konfiguracja tokena API '${TOKEN_NAME}'..."

if pveum user token list "${FULL_USER}" | grep -qw "${TOKEN_NAME}" 2>/dev/null; then
    echo " -> Wykryto istniejący token '${TOKEN_NAME}'. Usunięcie starego tokena w celu wygenerowania nowego klucza Secret..."
    pveum user token remove "${FULL_USER}" "${TOKEN_NAME}"
fi

echo " -> Generowanie nowego tokena API bez separacji uprawnień (--privsep 0)..."
TOKEN_OUTPUT=$(pveum user token add "${FULL_USER}" "${TOKEN_NAME}" --privsep 0)

echo " -> Przypisywanie ról ACL dla nowego tokena..."
pveum acl modify / -token "${FULL_TOKEN}" -roles PVEAdmin || true

# ------------------------------------------------------------------------------
# Podsumowanie i instrukcja
# ------------------------------------------------------------------------------
echo ""
echo "Podsumowanie przyznanych uprawnień dla tokena '${FULL_TOKEN}':"
pveum user token permissions "${FULL_USER}" "${TOKEN_NAME}" || true

echo ""
echo "================================================================="
echo " DANE DO WPROWADZENIA W HOME ASSISTANT (KOLEJNOŚĆ FORMULARZA):"
echo "================================================================="
echo " 1. Authentication method: Proxmox user - Proxmox VE authentication server"
echo " 2. Host: ${PROXMOX_IP}"
echo " 3. Username: ${FULL_TOKEN}"
echo " 4. Port: 8006"
echo " 5. [X] Use an API token  <-- ZAZNACZ TĘ OPCJĘ!"
echo " 6. [ ] Verify SSL certificate  <-- ODZNACZ TĘ OPCJĘ (wyłącz SSL)"
echo "================================================================="
echo " SECRET / VALUE (Wklej w następnym kroku jako Token ID / Secret):"
echo "$TOKEN_OUTPUT"
echo "================================================================="