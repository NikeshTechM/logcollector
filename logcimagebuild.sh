#!/bin/bash

set -e
set -o pipefail

# === Lock to prevent concurrent execution ===
LOCKFILE="/tmp/build_image.lock"
exec 200>$LOCKFILE
flock -n 200 || {
    echo "❌ Build already in progress. Exiting."
    exit 1
}

# === Variables ===
IMAGE_NAME="quay.io/nikesh_sar/log-collector"
USERNAME="nikesh_sar"
PASSWORD="Nikesh@123"
BUILD_DIR="."  # Path to directory with Dockerfile

LOG_DIR="/var/log/podman"
BUILD_LOG="${LOG_DIR}/build.log"
TIMESTAMP=$(date +"%Y%m%d%H%M%S")
TAG="${TIMESTAMP}"
FULL_IMAGE="${IMAGE_NAME}:${TAG}"

# === Setup logging ===
mkdir -p "$LOG_DIR"
chmod 755 "$LOG_DIR"
echo "🔁 Build started at $(date -Iseconds)" > "$BUILD_LOG"

# === Check Dockerfile exists ===
if [ ! -f "$BUILD_DIR/Dockerfile" ]; then
    echo "❌ Dockerfile not found in $BUILD_DIR" | tee -a "$BUILD_LOG"
    exit 1
fi

# === Remove previous images ===
echo "🧹 Checking for previous images matching $IMAGE_NAME..." | tee -a "$BUILD_LOG"
OLD_IMAGES=$(podman images --format "{{.Repository}}:{{.Tag}}" | grep "^${IMAGE_NAME}:" || true)

if [ -z "$OLD_IMAGES" ]; then
    echo "ℹ️ No previous images found for $IMAGE_NAME. Skipping deletion." | tee -a "$BUILD_LOG"
else
    echo "🔻 Found previous images. Removing..." | tee -a "$BUILD_LOG"
    while read -r old_image; do
        echo "   ➤ Removing $old_image" | tee -a "$BUILD_LOG"
        podman rmi -f "$old_image" >> "$BUILD_LOG" 2>&1 || echo "⚠️ Could not remove $old_image" | tee -a "$BUILD_LOG"
    done <<< "$OLD_IMAGES"
fi

echo "🟢 Proceeding to login and build..." | tee -a "$BUILD_LOG"

# === Login to Quay.io ===
echo "🔐 Logging into Quay.io..." | tee -a "$BUILD_LOG"
echo "$PASSWORD" | podman login quay.io -u "$USERNAME" --password-stdin >> "$BUILD_LOG" 2>&1
echo "✅ Login successful." | tee -a "$BUILD_LOG"

# === Build the image ===
{
    echo "=== Build Started at $(date -Iseconds) ==="
    podman build -t "$FULL_IMAGE" "$BUILD_DIR"
    echo "=== Build Finished at $(date -Iseconds) ==="
} >> "$BUILD_LOG" 2>&1

echo "✅ Successfully built new image: $FULL_IMAGE" | tee -a "$BUILD_LOG"

# === Prune unused containers and volumes ===
echo "🧽 Pruning unused containers..." | tee -a "$BUILD_LOG"
podman container prune -f >> "$BUILD_LOG" 2>&1
echo "✅ Pruned containers." | tee -a "$BUILD_LOG"

echo "🧽 Pruning unused volumes..." | tee -a "$BUILD_LOG"
podman volume prune -f >> "$BUILD_LOG" 2>&1
echo "✅ Pruned volumes." | tee -a "$BUILD_LOG"

# === Output the final image tag for downstream use ===
echo "$FULL_IMAGE"
