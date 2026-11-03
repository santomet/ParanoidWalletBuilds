# Coin Wallet (coin.space) — Linux x86_64

**Upstream:** Coin Wallet 6.31.0  
**Source:** <https://github.com/CoinSpace/CoinSpace/releases/tag/v6.31.0>  
**Platform:** Linux x86_64  
**Build type:** Repackaged official Flatpak → AppImage  
**AppImage:** `Coin.Wallet-6.31.0-x86_64.AppImage`  
**Size:** 115,784,184 bytes  
**SHA-256:** `22c87d4a838d57c0ae7d98f69fda3e655cef3c6a88c2d1fa946246e328603fd7`  
**Built:** 2026-11-03

## Read this first

This is **not** an independent source build. It takes the official Flatpak
published by CoinSpace and repackages its payload as an AppImage. It does not
prove that the official binary matches the public source.

The AppImage container is reproducible with the pinned tools and timestamp
below: rebuilding from the same Flatpak with the same appimagetool and
`SOURCE_DATE_EPOCH` produces the same SHA-256. The payload is the upstream
Flatpak payload.

## Inputs

| Input | Value |
| --- | --- |
| Upstream Flatpak | `Coin.Wallet.flatpak` v6.31.0 |
| Flatpak URL | <https://github.com/CoinSpace/CoinSpace/releases/download/v6.31.0/Coin.Wallet.flatpak> |
| Flatpak SHA-256 | `2fb1c76f7596bf28003251c187f904c96067eedf54e4f21a4973ad63360d5cc5` |
| appimagetool | 1.9.1 |
| appimagetool URL | <https://github.com/AppImage/appimagetool/releases/download/1.9.1/appimagetool-x86_64.AppImage> |
| appimagetool SHA-256 | `ed4ce84f0d9caff66f50bcca6ff6f35aae54ce8135408b3fa33abfc3cb384eb0` |
| `SOURCE_DATE_EPOCH` | `1792498843` (2026-10-20T12:20:43Z) |

## Reproduce

Requirements: Linux x86_64, `curl`, `flatpak`, `mksquashfs`, network access.

```bash
git clone https://github.com/santomet/ParanoidWalletBuilds.git
cd ParanoidWalletBuilds/coin.space
./build-appimage.sh 6.31.0
```

Expected output:

```text
AppImage: /.../Coin.Wallet-6.31.0-x86_64.AppImage
SHA-256:  22c87d4a838d57c0ae7d98f69fda3e655cef3c6a88c2d1fa946246e328603fd7
Reproduced the published AppImage hash.
```

If a different `space.coin.wallet` version is already installed:

```bash
flatpak uninstall --user space.coin.wallet
```

Then run the build again.

## Verify the published AppImage

```bash
sha256sum -c SHA256SUMS
```

To inspect the payload:

```bash
./Coin.Wallet-6.31.0-x86_64.AppImage --appimage-extract
grep '"version"' squashfs-root/resources/app/package.json
```

## Why not build from source?

The web frontend depends on the `@coinspace/cs-*` wallet libraries, which are
published to GitHub Packages (`npm.pkg.github.com`), not the public npm
registry. `npm ci` fails with `401 Unauthorized` without a token that has
package-read access. Upstream CI uses the `NPM_READ_TOKEN` secret for this.
The repository also has no AppImage maker upstream — it ships Flatpak and Snap
for Linux.

See [SOURCE_BUILD.md](./SOURCE_BUILD.md) for the source-build recipe and the
remaining blocker.

## Caveats

- `AppRun` passes `--no-sandbox`. AppImage mounts do not preserve the setuid
  bit on Electron's `chrome-sandbox`, so the Chromium sandbox cannot start
  normally. This is the usual tradeoff for Electron AppImages.
- Auto-update is disabled. The payload was built for the `flatpak`
  distribution, and Coin Wallet's updater does not support that outside
  Flatpak. Rebuild or download a new AppImage for updates.
- The AppImage is unsigned. The SHA-256 is the only integrity check published
  here.
- Only the launch screen was verified. Wallet creation, imports, signing, and
  transactions were not tested.
- The app writes data to `~/.config/Coin Wallet`, like the normal desktop
  build.
