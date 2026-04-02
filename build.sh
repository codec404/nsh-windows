#!/usr/bin/env bash
# windows/build.sh — Build nsh inside MSYS2 and collect all files needed
# by the Inno Setup installer.
#
# Run this script from an MSYS2 MinGW64 shell:
#   bash windows/build.sh
#
# Output: windows/dist/  — ready to be pointed at by nsh-setup.iss

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SRC_DIR="$REPO_ROOT/nsh"
DIST_DIR="$SCRIPT_DIR/dist"

echo "==> Checking MSYS2 environment..."
if [[ -z "${MSYSTEM:-}" ]]; then
    echo "ERROR: This script must be run inside an MSYS2 shell."
    echo "  Open 'MSYS2 MinGW 64-bit' from the Start Menu and re-run."
    exit 1
fi

echo "==> Installing dependencies via pacman..."
pacman -S --needed --noconfirm \
    mingw-w64-x86_64-gcc \
    mingw-w64-x86_64-readline \
    mingw-w64-x86_64-sqlite3 \
    mintty

echo "==> Building nsh..."
cd "$SRC_DIR"

# MinGW64 paths for readline and sqlite
RL_PREFIX="/mingw64"
SQ_PREFIX="/mingw64"

make clean
make \
    CC="gcc" \
    "RL_PREFIX=$RL_PREFIX" \
    "SQ_PREFIX=$SQ_PREFIX" \
    CFLAGS="-Wall -Wextra -Wpedantic -std=c11 -g -I$RL_PREFIX/include -I$SQ_PREFIX/include" \
    LDFLAGS="-L$RL_PREFIX/lib -lreadline -L$SQ_PREFIX/lib -lsqlite3"

echo "==> Collecting files into $DIST_DIR..."
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR/bin"
mkdir -p "$DIST_DIR/lib"

# Copy the nsh binary
cp "$SRC_DIR/build/nsh.exe" "$DIST_DIR/bin/nsh.exe"

# Copy MinTTY (the terminal window)
cp "$(which mintty).exe" "$DIST_DIR/bin/mintty.exe" 2>/dev/null || \
    cp "/mingw64/bin/mintty.exe" "$DIST_DIR/bin/mintty.exe"

# Bundle the MSYS2 runtime DLLs that nsh.exe depends on
echo "==> Bundling runtime DLLs..."
bundle_deps() {
    local binary="$1"
    # ldd output lines look like: "  libfoo.dll => /mingw64/bin/libfoo.dll (0x...)"
    ldd "$binary" 2>/dev/null \
        | awk '/\/mingw64\/bin\// { print $3 }' \
        | while read -r dll; do
            local name
            name="$(basename "$dll")"
            if [[ ! -f "$DIST_DIR/bin/$name" ]]; then
                echo "  Copying $name"
                cp "$dll" "$DIST_DIR/bin/$name"
            fi
        done
}

bundle_deps "$DIST_DIR/bin/nsh.exe"
bundle_deps "$DIST_DIR/bin/mintty.exe"

# Copy the MSYS2 runtime itself (msys-2.0.dll lives in /usr/bin)
if [[ -f "/usr/bin/msys-2.0.dll" ]]; then
    cp "/usr/bin/msys-2.0.dll" "$DIST_DIR/bin/"
fi

# Create the launcher script that opens MinTTY running nsh
cat > "$DIST_DIR/bin/nsh-terminal.sh" <<'EOF'
#!/usr/bin/env bash
# Launched by mintty; starts nsh as the interactive shell
exec /bin/nsh
EOF

echo ""
echo "==> Build complete."
echo "    Binaries are in: $DIST_DIR"
echo ""
echo "Next step: open windows/nsh-setup.iss in Inno Setup and click Build."
