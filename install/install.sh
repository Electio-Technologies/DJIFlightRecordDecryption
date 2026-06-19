#!/usr/bin/env bash
set -e

BINARY_NAME="FRSample"

INSTALL_DIR="${1:-/usr/local/bin}"

if [ "$EUID" -ne 0 ]; then
    echo "[ERROR] This script must be run as root or with sudo." >&2
    exit 1
fi

# Install dependencies
echo "[INFO] Updating package lists and installing dependencies..."
apt-get update -y
apt-get install -y libtomcrypt1 libtommath1 libprotobuf32t64 libcurl4t64

# Ensure the target directory exists
if [ ! -dir "$INSTALL_DIR" ]; then
    echo "[INFO] Directory $INSTALL_DIR does not exist. Creating it..."
    mkdir -p "$INSTALL_DIR"
fi

# Copy the bundled binary to the specified path
echo "[INFO] Installing ${BINARY_NAME} to ${INSTALL_DIR}..."
cp "./${BINARY_NAME}" "${INSTALL_DIR}/"
chmod +x "${INSTALL_DIR}/${BINARY_NAME}"

echo "[INFO] Successfully installed ${BINARY_NAME} to ${INSTALL_DIR}!"