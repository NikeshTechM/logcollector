#!/bin/bash

set -e  # Exit on any error

# === Variables ===
IMAGE_NAME="quay.io/nikesh_sar/log-collector"
USERNAME="nikesh_sar"
PASSWORD="Nikesh@123"

LOG_DIR="/var/log/podman"
BUILD_LOG="${LOG_DIR}/build.log"
PUSH_LOG="${LOG_DIR}/push.log"

# === Ensure Log Directory Exists ===
mkdir -p "$LOG_DIR"
chmod 755 "$LOG_DIR"

# === Start Fresh Push Log ===
echo "=== Push Started at $(date -Iseconds) ===" > "$PUSH_LOG"

# === Extract Tag from build.log ===
IMAGE_TAG=$(grep -oP "Successfully built new image: ${IMAGE_NAME}:\K[0-9]{14}" "$BUILD_LOG" | tail -1)

if [[ -z "$IMAGE_TAG" ]]; then
    echo "❌ Failed to extract image tag from build log." | tee -a "$PUSH_LOG"
    exit 1
fi

REMOTE_IMAGE="${IMAGE_NAME}:${IMAGE_TAG}"
echo "✅ Extracted image tag: $IMAGE_TAG" | tee -a "$PUSH_LOG"

# === Login to Quay.io ===
echo "$PASSWORD" | podman login quay.io -u "$USERNAME" --password-stdin >> "$PUSH_LOG" 2>&1

# === Check if tag already exists ===
if podman images --format "{{.Repository}}:{{.Tag}}" | grep -q "$REMOTE_IMAGE"; then
    echo "ℹ️ Image already tagged: $REMOTE_IMAGE" | tee -a "$PUSH_LOG"
else
    echo "🔄 Tagging image as ${REMOTE_IMAGE}..." | tee -a "$PUSH_LOG"
    podman tag "$IMAGE_NAME:latest" "$REMOTE_IMAGE" >> "$PUSH_LOG" 2>&1
    echo "✅ Tagging completed." | tee -a "$PUSH_LOG"
fi

# === Optional: Clean up old tags with same ID ===
IMAGE_ID=$(podman images --format "{{.ID}}" "$REMOTE_IMAGE")
OLD_TAGS=$(podman images --format "{{.Repository}}:{{.Tag}} {{.ID}}" | grep "$IMAGE_ID" | awk '{print $1}')

for tag in $OLD_TAGS; do
    if [[ "$tag" != "$REMOTE_IMAGE" ]]; then
        echo "🧹 Removing old tag: $tag" | tee -a "$PUSH_LOG"
        podman rmi "$tag" >> "$PUSH_LOG" 2>&1 || true
    fi
done

# === Push the Tagged Image ===
echo "🚀 Pushing image ${REMOTE_IMAGE} to Quay.io..." | tee -a "$PUSH_LOG"
if podman push "$REMOTE_IMAGE" >> "$PUSH_LOG" 2>&1; then
    echo "✅ Image push completed." | tee -a "$PUSH_LOG"
else
    echo "❌ Image push failed." | tee -a "$PUSH_LOG"
    exit 1
fi

# === Send MQTT + Upload to S3 ===
if python3 /root/ocppipeline/ota_setup/master.py "$REMOTE_IMAGE" container >> "$PUSH_LOG" 2>&1; then
    echo "✅ Notification sent to web app." | tee -a "$PUSH_LOG"
else
    echo "❌ Failed to send notification." | tee -a "$PUSH_LOG"
    exit 1
fi

echo "🎉 Push process completed successfully." | tee -a "$PUSH_LOG"
