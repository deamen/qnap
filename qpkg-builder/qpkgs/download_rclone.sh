#!/bin/sh
set -e

# Variables
RCLONE_VERSION="${RCLONE_VERSION:-1.68.1}"
BASE_IMAGE="quay.io/deamen/alpine-base:latest"
OUT_DIR="./rclone"
container=$(buildah from $BASE_IMAGE)
trap 'buildah rm $container' EXIT

# Install necessary tools
buildah run $container -- apk update
buildah run $container -- apk add --no-cache wget gnupg unzip bind-tools

# URLs
RCLONE_KEY_URL="https://rclone.org/KEYS"
ARM64_URL="https://github.com/rclone/rclone/releases/download/v$RCLONE_VERSION/rclone-v$RCLONE_VERSION-linux-arm64.zip"
AMD64_URL="https://github.com/rclone/rclone/releases/download/v$RCLONE_VERSION/rclone-v$RCLONE_VERSION-linux-amd64.zip"
SHA256SUMS_URL="https://github.com/rclone/rclone/releases/download/v$RCLONE_VERSION/SHA256SUMS"
EXPECTED_FINGERPRINT="FBF737ECE9F8AB18604BD2AC93935E02FF3B54FA"

# Download Rclone files
buildah run $container -- wget -P /tmp "$ARM64_URL"
buildah run $container -- wget -P /tmp "$AMD64_URL"
buildah run $container -- wget -P /tmp "$SHA256SUMS_URL"

# Import GPG key and verify fingerprint
buildah run $container -- wget -O /tmp/KEYS "$RCLONE_KEY_URL"
buildah run $container -- gpg --import /tmp/KEYS
fingerprint=$(buildah run $container -- gpg --list-keys --with-colons | grep "$EXPECTED_FINGERPRINT" || true)

if [ -z "$fingerprint" ]; then
  echo "Fingerprint verification failed."
  exit 1
fi

# Cross-check fingerprint using DNS
dns_fingerprint=$(buildah run $container -- dig +short txt key.rclone.org | tr -d '"')
if [ "$dns_fingerprint" != "$EXPECTED_FINGERPRINT" ]; then
  echo "DNS fingerprint verification failed."
  exit 1
fi

# Verify SHA256SUMS signature
buildah run $container -- gpg --verify /tmp/SHA256SUMS

# Manual checksum verification for each specific downloaded file
buildah run $container -- sh -c "
  cd /tmp &&
  sha256sum -c SHA256SUMS 2>/dev/null | grep 'rclone-v$RCLONE_VERSION-linux-arm64.zip: OK' &&
  sha256sum -c SHA256SUMS 2>/dev/null | grep 'rclone-v$RCLONE_VERSION-linux-amd64.zip: OK'
"

# Unzip the downloaded files
buildah run $container -- unzip /tmp/rclone-v$RCLONE_VERSION-linux-arm64.zip -d /tmp
buildah run $container -- unzip /tmp/rclone-v$RCLONE_VERSION-linux-amd64.zip -d /tmp

# Create the copy script to move binaries to arm_64 and x86_64 folders
copy_script="copy_rclone_binaries.sh"
cat << 'EOF' > $copy_script
#!/bin/sh
container=$1
OUT_DIR=$2

mnt=$(buildah mount $container)
mkdir -p "$OUT_DIR/arm_64" "$OUT_DIR/x86_64"
cp "$mnt/tmp/rclone-v1.68.1-linux-arm64/rclone" "$OUT_DIR/arm_64/"
cp "$mnt/tmp/rclone-v1.68.1-linux-amd64/rclone" "$OUT_DIR/x86_64/"
buildah umount $container
EOF
chmod a+x $copy_script

# Use buildah unshare to copy the binaries from the container to the host
echo "Copying the rclone binaries from the builder container to the host..."
buildah unshare ./$copy_script "$container" "$OUT_DIR"

# Clean up
rm -rf "$copy_script"
echo "Rclone binaries have been copied to $OUT_DIR and verified."