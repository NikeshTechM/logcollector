#!/bin/bash

set -e  # Exit on any error

# === Variables ===
IMAGE_NAME="quay.io/nikesh_sar/log-collector"
USERNAME="nikesh_sar"
PASSWORD="Nikesh@123"

BUILD_DIR="."  # Change if Dockerfile is in a subdirectory
LOG_DIR="/var/log/podman"
BUILD_LOG="${LOG_DIR}/build.log"

# === Ensure Log Directory Exists ===
mkdir -p "$LOG_DIR"
chmod 755 "$LOG_DIR"

# === Start Fresh Build Log ===
rm -f "$BUILD_LOG"
touch "$BUILD_LOG"

# === Check Dockerfile Exists ===
if [ ! -f "$BUILD_DIR/Dockerfile" ]; then
  echo "❌ Dockerfile not found in $BUILD_DIR" | tee -a "$BUILD_LOG"
  exit 1
fi

# === Generate Tag Using Current Date-Time ===
TIMESTAMP=$(date +"%Y%m%d%H%M%S")
TAG="$TIMESTAMP"
FULL_IMAGE="${IMAGE_NAME}:${TAG}"

# === Remove Previous Local Images Before Build ===
echo "🧹 Removing all previous local images for $IMAGE_NAME..." | tee -a "$BUILD_LOG"
podman images --format "{{.Repository}}:{{.Tag}}" | grep "^${IMAGE_NAME}:" | while read -r old_image; do
  echo "🔻 Removing image: $old_image" | tee -a "$BUILD_LOG"
  podman rmi "$old_image" >> "$BUILD_LOG" 2>&1 || echo "⚠️ Failed to remove $old_image" | tee -a "$BUILD_LOG"
done

# === Login to Quay.io ===
echo "🔐 Logging into Quay.io..." | tee -a "$BUILD_LOG"
echo "$PASSWORD" | podman login quay.io -u "$USERNAME" --password-stdin >> "$BUILD_LOG" 2>&1
echo "✅ Login successful." | tee -a "$BUILD_LOG"

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

echo "✅ Successfully built new image: $FULL_IMAGE" | tee -a "$BUILD_LOG"

# === Prune Unused Containers and Volumes ===
echo "🧽 Pruning unused containers and volumes..." | tee -a "$BUILD_LOG"
podman container prune -f >> "$BUILD_LOG" 2>&1
echo "✅ Pruned unused containers." | tee -a "$BUILD_LOG"
podman volume prune -f >> "$BUILD_LOG" 2>&1
echo "✅ Pruned unused volumes." | tee -a "$BUILD_LOG"

# === Output Image Tag (for chaining or follow-up scripts) ===
echo "$FULL_IMAGE"
