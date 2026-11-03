#!/usr/bin/env bash
#
# Build a Coin Wallet AppImage by repackaging the official Flatpak.
#
# Usage: ./build-appimage.sh [version]
#   version defaults to 6.31.0
#
# The AppImage container is reproducible when built with the pinned
# appimagetool and SOURCE_DATE_EPOCH below. The payload itself is the
# official Flatpak payload, verified against FLATPAK_SHA256.
#
# Requirements: curl, flatpak, mksquashfs, a user session (no root needed).
#
set -euo pipefail

VERSION="${1:-6.31.0}"
WORKDIR="$(cd "$(dirname "$0")" && pwd)"

FLATPAK="$WORKDIR/Coin.Wallet.flatpak"
FLATPAK_SHA256="2fb1c76f7596bf28003251c187f904c96067eedf54e4f21a4973ad63360d5cc5"

APPIMAGETOOL="$WORKDIR/appimagetool-1.9.1-x86_64.AppImage"
APPIMAGETOOL_URL="https://github.com/AppImage/appimagetool/releases/download/1.9.1/appimagetool-x86_64.AppImage"
APPIMAGETOOL_SHA256="ed4ce84f0d9caff66f50bcca6ff6f35aae54ce8135408b3fa33abfc3cb384eb0"

# Timestamp of the upstream Coin Wallet v6.31.0 release (2026-10-20T12:20:43Z).
SOURCE_DATE_EPOCH="${SOURCE_DATE_EPOCH:-1792498843}"
EXPECTED_APPIMAGE_SHA256="22c87d4a838d57c0ae7d98f69fda3e655cef3c6a88c2d1fa946246e328603fd7"

APPDIR="$WORKDIR/CoinWallet.AppDir"
OUT="$WORKDIR/Coin.Wallet-${VERSION}-x86_64.AppImage"

check_sha256() {
  local file="$1" expected="$2"
  local actual
  actual="$(sha256sum "$file" | awk '{print $1}')"
  if [ "$actual" != "$expected" ]; then
    echo "SHA-256 mismatch for $file" >&2
    echo "  expected: $expected" >&2
    echo "  actual:   $actual" >&2
    exit 1
  fi
}

if [ ! -f "$FLATPAK" ]; then
  echo "Downloading official Flatpak v${VERSION}..."
  curl -L --fail -o "$FLATPAK" \
    "https://github.com/CoinSpace/CoinSpace/releases/download/v${VERSION}/Coin.Wallet.flatpak"
fi
check_sha256 "$FLATPAK" "$FLATPAK_SHA256"

flatpak remote-add --user --if-not-exists flathub \
  https://flathub.org/repo/flathub.flatpakrepo
flatpak install --user --noninteractive --assumeyes "$FLATPAK"

APP="$(flatpak info --user --show-location space.coin.wallet)"
if [ ! -x "$APP/files/lib/space.coin.wallet/coin" ]; then
  echo "Could not find the installed Coin Wallet binary." >&2
  exit 1
fi

ACTUAL="$(sed -n 's/.*"version": "\([^"]*\)".*/\1/p' \
  "$APP/files/lib/space.coin.wallet/resources/app/package.json" | head -1)"
if [ "$ACTUAL" != "$VERSION" ]; then
  echo "Installed app is $ACTUAL, but $VERSION was requested." >&2
  echo "Remove the existing user Flatpak first:" >&2
  echo "  flatpak uninstall --user space.coin.wallet" >&2
  exit 1
fi

echo "Staging AppDir..."
rm -rf "$APPDIR"
mkdir -p "$APPDIR"
cp -a "$APP/files/lib/space.coin.wallet/." "$APPDIR/"

# Reuse the 512x512 app icon shipped with the web build.
cp "$APPDIR/resources/app/dist/android-chrome-512x512.png" "$APPDIR/coin.png"
ln -sf coin.png "$APPDIR/.DirIcon"

cat > "$APPDIR/AppRun" <<'EOF'
#!/bin/sh
HERE=$(dirname "$(readlink -f "$0")")
exec "$HERE/coin" --no-sandbox "$@"
EOF
chmod +x "$APPDIR/AppRun"

cat > "$APPDIR/coin.desktop" <<'EOF'
[Desktop Entry]
Name=Coin Wallet
Comment=Self-custodial multi-currency crypto wallet
Exec=coin %U
Icon=coin
Type=Application
Terminal=false
StartupNotify=true
Categories=Office;Finance;
MimeType=x-scheme-handler/coinspace;x-scheme-handler/bitcoincash;x-scheme-handler/bitcoin;x-scheme-handler/cardano;x-scheme-handler/dash;x-scheme-handler/dogecoin;x-scheme-handler/ethereum;x-scheme-handler/litecoin;x-scheme-handler/monero;x-scheme-handler/solana;x-scheme-handler/stellar;x-scheme-handler/ripple;
EOF

if [ ! -x "$APPIMAGETOOL" ]; then
  echo "Downloading appimagetool 1.9.1..."
  curl -L --fail -o "$APPIMAGETOOL" "$APPIMAGETOOL_URL"
  chmod +x "$APPIMAGETOOL"
fi
check_sha256 "$APPIMAGETOOL" "$APPIMAGETOOL_SHA256"

echo "Building AppImage..."
rm -f "$OUT"
SOURCE_DATE_EPOCH="$SOURCE_DATE_EPOCH" ARCH=x86_64 \
  "$APPIMAGETOOL" --appimage-extract-and-run --no-appstream "$APPDIR" "$OUT"

ACTUAL_SHA256="$(sha256sum "$OUT" | awk '{print $1}')"
echo
echo "AppImage: $OUT"
echo "SHA-256:  $ACTUAL_SHA256"
if [ "$ACTUAL_SHA256" = "$EXPECTED_APPIMAGE_SHA256" ]; then
  echo "Reproduced the published AppImage hash."
else
  echo "WARNING: hash differs from the published artifact." >&2
  echo "Expected: $EXPECTED_APPIMAGE_SHA256" >&2
  echo "The AppDir payload or the build environment differs." >&2
fi
