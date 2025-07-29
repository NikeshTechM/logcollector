#!/bin/bash

set -e  # Exit on error

# === Variables ===
IMAGE_NAME="quay.io/nikesh_sar/log-collector"
TAG="$(date -u +"%Y%m%d%H%M%S")"
FULL_IMAGE="${IMAGE_NAME}:${TAG}"

USERNAME="nikesh_sar"
PASSWORD="Nikesh@123"
BUILD_DIR="/root/ocppipeline/oclogs/logcollector"

LOG_DIR="/var/log/podman"
BUILD_LOG="${LOG_DIR}/build.log"

# === Setup log directory ===
mkdir -p "$LOG_DIR"
chmod 755 "$LOG_DIR"
rm -f "$BUILD_LOG"
touch "$BUILD_LOG"

# === Dockerfile check ===
if [ ! -f "$BUILD_DIR/Dockerfile" ]; then
    echo "❌ Dockerfile not found in $BUILD_DIR" | tee -a "$BUILD_LOG"
    exit 1
fi

# === Login ===
echo "$PASSWORD" | podman login quay.io -u "$USERNAME" --password-stdin >> "$BUILD_LOG" 2>&1

# === Build the image ===
{
    echo "=== Build Started at $(date -Iseconds) ==="
    podman build -t "$FULL_IMAGE" "$BUILD_DIR"
    echo "=== Build Finished at $(date -Iseconds) ==="
    echo "✅ Successfully built new image: $FULL_IMAGE"
} >> "$BUILD_LOG" 2>&1

# === Exit with status ===
exit 0
