#!/usr/bin/env bash
# backup-pi.sh – create a timestamped tarball of pi sessions, config, cache and logs
# ---------------------------------------------------------------
# Requirements: bash, cp, tar (standard on macOS / Linux)
# Target: pi CLI (https://pi.dev) version 1.4.0
# ---------------------------------------------------------------
# Quick‑and‑safe sandbox test:
#   PI_SANDBOX="/tmp/pi-test-$$(date +%s)"
#   mkdir -p "$PI_SANDBOX"
#   HOME="$PI_SANDBOX" ./backup-pi.sh
#   # archive is created at $HOME/pi-backup-<timestamp>.tar.gz
#   # (i.e. $PI_SANDBOX/pi-backup-<timestamp>.tar.gz)
#   # restore into a fresh sandbox to verify
#   PI_SANDBOX2="/tmp/pi-test-restore-$$(date +%s)"
#   mkdir -p "$PI_SANDBOX2"
#   HOME="$PI_SANDBOX2" ./restore-pi.sh "$PI_SANDBOX/pi-backup-<timestamp>.tar.gz"
#   find "$PI_SANDBOX2/.pi/agent/sessions" -name "*.jsonl" | wc -l
#   HOME="$PI_SANDBOX2" pi
# ---------------------------------------------------------------

set -euo pipefail   # abort on error, treat unset vars as errors

# 1️⃣  Create a unique backup directory name
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="${HOME}/pi-backup-${TIMESTAMP}"
TMP_DIR="${BACKUP_DIR}_tmp"

# 2️⃣  Make a temporary working folder (won’t be archived)
mkdir -p "${TMP_DIR}"

# 3️⃣  Copy the needed sub‑folders (if they exist)
mkdir -p "${TMP_DIR}/sessions"
cp -r "${HOME}/.pi/agent/sessions/"* "${TMP_DIR}/sessions"/ 2>/dev/null || true

mkdir -p "${TMP_DIR}/config"
cp -r "${HOME}/.pi/agent/config/"* "${TMP_DIR}/config"/ 2>/dev/null || true

mkdir -p "${TMP_DIR}/cache"
cp -r "${HOME}/.pi/agent/cache/"* "${TMP_DIR}/cache"/ 2>/dev/null || true

mkdir -p "${TMP_DIR}/logs"
cp -r "${HOME}/.pi/agent/logs/"* "${TMP_DIR}/logs"/ 2>/dev/null || true

# 4️⃣  Tar the temporary folder (the archive will be placed in $HOME)
ARCHIVE="${HOME}/pi-backup-${TIMESTAMP}.tar.gz"
tar -czf "${ARCHIVE}" -C "${TMP_DIR}" .

# 5️⃣  Clean up the temporary folder
rm -rf "${TMP_DIR}"

echo "✅ Backup created: ${ARCHIVE}"