#!/usr/bin/env bash
set -e

BINARY_NAME="FRSample"
INSTALL_DIR="${1:-/usr/local/bin}"

# ─── THE FIX: FIND WHERE THE SCRIPT LIVES ───
# This finds the absolute directory path of this script, resolving symlinks
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_BINARY="${SCRIPT_DIR}/${BINARY_NAME}"

# Ensure run as root
if [ "$EUID" -ne 0 ]; then
    echo "[ERROR] This script must be run as root or with sudo." >&2
    exit 1
fi

# Verify the binary actually exists next to the script before proceeding
if [ ! -f "$SOURCE_BINARY" ]; then
    echo "[ERROR] Cannot find ${BINARY_NAME} at ${SOURCE_BINARY}" >&2
    exit 1
fi

# --- AUTOMATIC CLEANUP SETUP ---
SCRATCH_DIR=$(mktemp -d -t my-app-build-XXXXXX)
cleanup() {
    echo "[INFO] Cleaning up temporary installation files..."
    rm -rf "$SCRATCH_DIR"
}
trap cleanup EXIT INT TERM

# Copy the binary from its real location into our secure scratch directory
cp "$SOURCE_BINARY" "$SCRATCH_DIR/"
cd "$SCRATCH_DIR"

# Install dependencies
echo "[INFO] Updating package lists and installing dependencies..."
apt-get update -y
# Try installing the t64 versions. If it fails, install the non-t64 versions instead.
if ! apt-get install -y libtomcrypt1 libtommath1 libprotobuf32t64 libcurl4t64; then
    echo "[INFO] t64 packages not found. Falling back to Debian 12 / older Ubuntu packages..."
    apt-get install -y libtomcrypt1 libtommath1 libprotobuf32 libcurl4
fi

# Ensure target directory exists
if [ ! -d "$INSTALL_DIR" ]; then
    mkdir -p "$INSTALL_DIR"
fi

# Copy binary to final destination
echo "[INFO] Installing ${BINARY_NAME} to ${INSTALL_DIR}..."
cp "./${BINARY_NAME}" "${INSTALL_DIR}/"
chmod +x "${INSTALL_DIR}/${BINARY_NAME}"

echo "[INFO] Successfully installed ${BINARY_NAME} to ${INSTALL_DIR}!"