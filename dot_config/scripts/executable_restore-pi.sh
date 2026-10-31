#!/usr/bin/env bash
# restore-pi.sh – extract a pi backup tarball back into $HOME
# ---------------------------------------------------------
# Usage:   restore-pi.sh <archive.tar.gz>
# Target: pi CLI (https://pi.dev) version 1.4.0
# ---------------------------------------------------------
# Quick‑and‑safe sandbox test:
#   PI_SANDBOX="/tmp/pi-test-$$(date +%s)"
#   mkdir -p "$PI_SANDBOX"
#   HOME="$PI_SANDBOX" ./restore-pi.sh /path/to/backup.tar.gz
#   # verify
#   find "$PI_SANDBOX/.pi/agent/sessions" -name "*.jsonl" | wc -l
#   # run pi in sandbox
#   HOME="$PI_SANDBOX" pi
# ---------------------------------------------------------

set -euo pipefail

# ---------- Helper ----------
usage() {
    echo "Usage: $0 <archive.tar.gz>"
    echo "  <archive.tar.gz>  Path to the backup created by backup-pi.sh"
    exit 1
}

# ---------- Argument check ----------
if [[ $# -ne 1 ]]; then
    usage
fi

ARCHIVE="$1"

# ---------- Verify archive ----------
if [[ ! -f "${ARCHIVE}" ]]; then
    echo "❌ Archive not found: ${ARCHIVE}"
    exit 1
fi

# ---------- Extract ----------
TMP_DIR=$(mktemp -d)
tar -xzf "${ARCHIVE}" -C "${TMP_DIR}"

# ---------- Find the actual root inside the extracted temp dir ----------
# If there's exactly one top-level directory, use it; otherwise use TMP_DIR directly
ROOT="${TMP_DIR}"
TOP_DIRS=$(find "${TMP_DIR}" -maxdepth 1 -type d)
if [[ $(echo "$TOP_DIRS" | wc -l) -eq 2 ]]; then
    ROOT=$(echo "$TOP_DIRS" | tail -1)
fi

# ---------- Restore each subtree ----------
mkdir -p "${HOME}/.pi/agent/sessions"
cp -r "${ROOT}/sessions/"* "${HOME}/.pi/agent/sessions"/ 2>/dev/null || true

mkdir -p "${HOME}/.pi/agent/config"
cp -r "${ROOT}/config/"* "${HOME}/.pi/agent/config"/ 2>/dev/null || true

mkdir -p "${HOME}/.pi/agent/cache"
cp -r "${ROOT}/cache/"* "${HOME}/.pi/agent/cache"/ 2>/dev/null || true

mkdir -p "${HOME}/.pi/agent/logs"
cp -r "${ROOT}/logs/"* "${HOME}/.pi/agent/logs"/ 2>/dev/null || true

# ---------- Clean up ----------
rm -rf "${TMP_DIR}"

echo "✅ Restore completed from ${ARCHIVE}"