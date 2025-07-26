IMAGE_NAME="quay.io/nikesh_sar/log-collector"
TAG=$(date -u +"%Y%m%d%H%M%S")
FULL_IMAGE="${IMAGE_NAME}:${TAG}"

USERNAME="nikesh_sar"
PASSWORD="Nikesh@123"
BUILD_DIR="/root/ocppipeline/oclogs/logcollector"

mkdir -p /var/log/podman
chmod 755 /var/log/podman

BUILD_LOG="/var/log/podman/build.log"

if [ -f "$BUILD_LOG" ]; then
    rm "$BUILD_LOG"
fi
touch "$BUILD_LOG"

if [ ! -f "$BUILD_DIR/Dockerfile" ]; then
    echo "❌ Dockerfile not found in $BUILD_DIR" | tee -a "$BUILD_LOG"
    exit 1
fi

echo "$PASSWORD" | podman login quay.io -u "$USERNAME" --password-stdin >> "$BUILD_LOG" 2>&1

{
    echo "=== Build Started at $(date -Iseconds) ==="
    podman build -t "$FULL_IMAGE" "$BUILD_DIR"
    BUILD_STATUS=$?
    echo "=== Build Finished at $(date -Iseconds) ==="
} >> "$BUILD_LOG" 2>&1

if [ $BUILD_STATUS -ne 0 ]; then
    echo "❌ Build failed. Check $BUILD_LOG for details." | tee -a "$BUILD_LOG"
    exit 1
fi

echo "✅ Successfully built new image: $FULL_IMAGE" | tee -a "$BUILD_LOG"
