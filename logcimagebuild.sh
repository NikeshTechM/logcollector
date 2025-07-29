#!/bin/bash

set -e  # Exit on any error

# === Variables ===
IMAGE_NAME="quay.io/nikesh_sar/log-collector"
USERNAME="nikesh_sar"
PASSWORD="Nikesh@123"

BUILD_DIR="."  # Adjust if needed
HASH_FILE="/var/log/podman/last_build.hash"
LOG_DIR="/var/log/podman"
BUILD_LOG="${LOG_DIR}/build.log"

# === Ensure Log Directory Exists ===
mkdir -p "$LOG_DIR"
chmod 755 "$LOG_DIR"

# === Start Fresh Build Log ===
rm -f "$BUILD_LOG"
touch "$BUILD_LOG"

# === Check Dockerfile Existence ===
if [ ! -f "$BUILD_DIR/Dockerfile" ]; then
  echo "❌ Dockerfile not found in $BUILD_DIR" | tee -a "$BUILD_LOG"
  exit 1
fi

# === Generate Tag Using Current Date-Time ===
TIMESTAMP=$(date +"%Y%m%d%H%M%S")
TAG="$TIMESTAMP"
FULL_IMAGE="${IMAGE_NAME}:${TAG}"

# === Login to Quay.io ===
echo "$PASSWORD" | podman login quay.io -u "$USERNAME" --password-stdin >> "$BUILD_LOG" 2>&1

# === Build Image with Timestamp Tag ===
{
  echo "=== Build Started at $(date -Iseconds) ==="
  podman build -t "$FULL_IMAGE" "$BUILD_DIR"
  BUILD_STATUS=$?
  echo "=== Build Finished at $(date -Iseconds) ==="
} >> "$BUILD_LOG" 2>&1

# === Build Result Check ===
if [ $BUILD_STATUS -ne 0 ]; then
  echo "❌ Build failed. Check $BUILD_LOG for details." | tee -a "$BUILD_LOG"
  exit 1
fi

echo "Successfully built new image: $FULL_IMAGE" | tee -a "$BUILD_LOG"

# === Optionally: Output the image tag for chaining ===
echo "$FULL_IMAGE"
