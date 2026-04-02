#!/usr/bin/env bash
# windows/build.sh — Build nsh inside MSYS2 (MSYS environment) and collect
# all files needed by the Inno Setup installer.
#
# IMPORTANT: Run this from "MSYS2 MSYS" shell — NOT "MSYS2 MinGW 64-bit".
#   Open Start Menu → MSYS2 → "MSYS2 MSYS"
#
# Output: dist/  — ready to be pointed at by nsh-setup.iss

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NSH_SRC="$HOME/nsh"           # cloned nsh repo
DIST_DIR="$SCRIPT_DIR/dist"

echo "==> Checking MSYS2 MSYS environment..."
if [[ "${MSYSTEM:-}" != "MSYS" ]]; then
    echo "ERROR: This script must be run in the 'MSYS2 MSYS' shell."
    echo "  Open Start Menu → MSYS2 → 'MSYS2 MSYS' and re-run."
    echo "  (You are currently in: ${MSYSTEM:-unknown})"
    exit 1
fi

echo "==> Installing dependencies..."
pacman -S --needed --noconfirm \
    gcc \
    make \
    libreadline-devel \
    libsqlite-devel

echo "==> Building nsh..."
cd "$NSH_SRC"

make clean
make \
    CC="gcc" \
    RL_PREFIX="/usr" \
    SQ_PREFIX="/usr" \
    CFLAGS="-Wall -Wextra -Wpedantic -std=c11 -g -D_GNU_SOURCE -I/usr/include -I/usr/include/readline" \
    LDFLAGS="-L/usr/lib -lreadline -lsqlite3"

echo "==> Collecting files into $DIST_DIR..."
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR/bin"

# Copy the nsh binary
cp "$NSH_SRC/build/nsh.exe" "$DIST_DIR/bin/nsh.exe"

# Copy mintty (already installed as part of MSYS2)
cp "/usr/bin/mintty.exe" "$DIST_DIR/bin/mintty.exe"

# Copy the MSYS2 POSIX runtime DLL (required by nsh.exe — this is what
# provides fork/exec/signals on Windows, same as Git Bash)
cp "/usr/bin/msys-2.0.dll" "$DIST_DIR/bin/"

# Bundle other DLLs that nsh.exe depends on
echo "==> Bundling runtime DLLs..."
ldd "$DIST_DIR/bin/nsh.exe" 2>/dev/null \
    | awk '/\/usr\/bin\// { print $3 }' \
    | while read -r dll; do
        name="$(basename "$dll")"
        if [[ ! -f "$DIST_DIR/bin/$name" ]]; then
            echo "  Copying $name"
            cp "$dll" "$DIST_DIR/bin/$name"
        fi
    done

echo ""
echo "==> Build complete. Files are in: $DIST_DIR"
echo ""
echo "Next: open nsh-setup.iss in Inno Setup and click Build → Compile."
