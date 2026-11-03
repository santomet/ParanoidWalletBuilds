#!/usr/bin/env bash
#
# Verify the published AppImage and, if the official Flatpak is installed,
# compare its payload with the AppImage payload.
#
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
cd "$HERE"

APPIMAGE="Coin.Wallet-6.31.0-x86_64.AppImage"
if [ ! -f "$APPIMAGE" ]; then
  echo "Missing $APPIMAGE" >&2
  exit 1
fi

echo "== Outer SHA-256 =="
sha256sum -c SHA256SUMS

echo "== Extracting AppImage =="
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
(
  cd "$TMP"
  "$HERE/$APPIMAGE" --appimage-extract >/dev/null
)

if ! grep -q '"version": "6.31.0"' "$TMP/squashfs-root/resources/app/package.json"; then
  echo "Unexpected embedded version:" >&2
  grep '"version"' "$TMP/squashfs-root/resources/app/package.json" >&2 || true
  exit 1
fi
echo "Embedded version: 6.31.0"

if flatpak info --user space.coin.wallet >/dev/null 2>&1; then
  echo "== Comparing payload with the installed official Flatpak =="
  SRC="$(flatpak info --user --show-location space.coin.wallet)/files/lib/space.coin.wallet/resources/app"
  diff -r "$SRC" "$TMP/squashfs-root/resources/app" >/dev/null
  echo "Payload matches the installed official Flatpak."
else
  echo "Flatpak not installed; skipping payload comparison."
fi

echo "OK"
