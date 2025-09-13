#!/bin/bash
set -e

echo "Installing code-server..."

###############################################
# Detect architecture for code-server
###############################################
ARCH_RAW="$(uname -m)"
case "$ARCH_RAW" in
  aarch64|arm64) ARCH="linux-arm64" ;;
  x86_64)        ARCH="linux-amd64" ;;
  armv7l)        ARCH="linux-armv7l" ;;
  *) echo "Unsupported architecture: $ARCH_RAW" >&2; exit 1 ;;
esac
echo "Detected architecture: $ARCH_RAW -> $ARCH"

###############################################
# Fetch latest code-server release
###############################################
echo "Fetching latest code-server version..."
if command -v jq >/dev/null 2>&1; then
    VERSION="$(curl -fsSL https://api.github.com/repos/coder/code-server/releases/latest \
      | jq -r '.tag_name' | sed 's/^v//')"
else
    VERSION="$(curl -fsSL https://api.github.com/repos/coder/code-server/releases/latest \
      | awk -F'\"' '/\"tag_name\":/ {print $4}' | sed 's/^v//' | head -n1)"
fi

[ -z "$VERSION" ] && { echo "Error: Could not determine latest version" >&2; exit 1; }
echo "Latest code-server version: $VERSION"

###############################################
# Download and install code-server
###############################################
URL="https://github.com/coder/code-server/releases/download/v$VERSION/code-server-$VERSION-$ARCH.tar.gz"
echo "Downloading from $URL"

rm -rf /tmp/code-server
if ! curl -fsSL "$URL" | tar -xz -C /tmp; then
    echo "Error: Failed to download or extract code-server" >&2
    exit 1
fi

if [ ! -d "/tmp/code-server-$VERSION-$ARCH" ]; then
    echo "Error: Expected directory /tmp/code-server-$VERSION-$ARCH not found" >&2
    exit 1
fi
mv "/tmp/code-server-$VERSION-$ARCH" /tmp/code-server
chmod +x /tmp/code-server/bin/code-server



###############################################
# Start code-server
###############################################
echo "Starting code-server..."
cd "/tmp/code-server/"
./bin/code-server --auth none --port 13337 --bind-addr 0.0.0.0 >/tmp/code-server.log 2>&1 &
PID=$!

sleep 2
if kill -0 "$PID" 2>/dev/null; then
    echo "✓ code-server installation complete"
    echo "✓ PID: $PID"
    echo "✓ Access at: http://localhost:13337"
else
    echo "Error: code-server failed to start" >&2
    echo "=== /tmp/code-server.log ===" >&2
    [ -f /tmp/code-server.log ] && cat /tmp/code-server.log >&2
    echo "============================" >&2
    exit 1
fi
