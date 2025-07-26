#!/bin/bash

# === Variables ===
IMAGE_NAME="quay.io/nikesh_sar/log-collector"
TAG="latest"
FULL_IMAGE="${IMAGE_NAME}:${TAG}"

USERNAME="nikesh_sar"
PASSWORD="Nikesh@123"

# Build directory where the Dockerfile exists
#autosd  path
BUILD_DIR="/root/ocppipeline/oclogs/logcollector"



# === Ensure Log Directory Exists ===
mkdir -p /var/log/podman
chmod 755 /var/log/podman

BUILD_LOG="/var/log/podman/build.log"

# === Delete existing build log file and create a new empty one ===
if [ -f "$BUILD_LOG" ]; then
  rm "$BUILD_LOG"
fi
touch "$BUILD_LOG"

# === Dockerfile Existence Check ===
if [ ! -f "$BUILD_DIR/Dockerfile" ]; then
  echo "❌ Dockerfile not found in $BUILD_DIR" | tee -a "$BUILD_LOG"
  exit 1
fi

# === Login to Quay.io (optional if push not needed) ===
echo "$PASSWORD" | podman login quay.io -u "$USERNAME" --password-stdin >> "$BUILD_LOG" 2>&1

# === Build Image with tag 'latest' ===
{
  echo "=== Build Started at $(date -Iseconds) ==="
  podman build -t "$FULL_IMAGE" "$BUILD_DIR"
  BUILD_STATUS=$?
  echo "=== Build Finished at $(date -Iseconds) ==="
} >> "$BUILD_LOG" 2>&1

# Check build success
if [ $BUILD_STATUS -ne 0 ]; then
  echo "❌ Build failed. Check $BUILD_LOG for details." | tee -a "$BUILD_LOG"
  exit 1
fi

echo "✅ Successfully built new image: $FULL_IMAGE" | tee -a "$BUILD_LOG"
