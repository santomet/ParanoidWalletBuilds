# Building Coin Wallet from source

This is the recipe for a true source build. It is **not** what produced the
released AppImage in this folder. The released AppImage is a repack of the
official Flatpak; see [README.md](./README.md).

## Blocker: private GitHub Packages

`web/package.json` depends on packages such as:

- `@coinspace/cs-bitcoin-wallet`
- `@coinspace/cs-evm-wallet`
- `@coinspace/cs-tron-wallet`
- `@coinspace/cs-monero-wallet`
- and the rest of the `@coinspace/cs-*` family

They are published to `npm.pkg.github.com`, not to the public npm registry.
Without a token that can read them, `npm ci` stops with:

```text
401 Unauthorized - GET https://npm.pkg.github.com/@coinspace%2fcs-tron-wallet
```

Upstream CI uses the `NPM_READ_TOKEN` secret. A token with `read:packages`
access is required. The public GitHub repositories under
<https://github.com/CoinSpace> contain some of the wallet libraries, but not
all of the packages and versions used by the web app, so building every
dependency from public source is not a drop-in replacement.

## Build

```bash
git clone https://github.com/CoinSpace/CoinSpace.git
cd CoinSpace
git checkout v6.31.0

export NODE_AUTH_TOKEN="<token with read:packages>"
# npm reads this only if the registry auth line is configured:
echo "//npm.pkg.github.com/:_authToken=\${NODE_AUTH_TOKEN}" >> web/.npmrc

npm --prefix web ci
npm --prefix electron ci

export VITE_BUILD_TYPE=electron
export VITE_PLATFORM=linux
export VITE_DISTRIBUTION=flatpak
export VITE_SITE_URL=https://coin.space
export VITE_API_HOST=coin.space
export VITE_VERSION=6.31.0
export VITE_NAME=coinwallet
export VITE_COMMIT="$(git rev-parse HEAD)"

npm --prefix web run build
npm --prefix electron run package -- --platform=linux --arch=x64
```

The packaged app lands in `electron/out/`. The exact directory name depends on
the Electron Forge version, for example:

```text
electron/out/Coin Wallet-linux-x64/
```

At that point you can either wrap that directory in an AppDir and run
`appimagetool`, or add an `appimage` distribution to
`electron/build.js`/`electron/forge.config.js` and use an AppImage maker.

## Reproducibility is not guaranteed

Even with the private packages, a source build is not guaranteed to be
byte-identical to the official Flatpak. Electron, Vite, native modules, and
the packaging tools all introduce nondeterminism. The repack in this folder
sidesteps that by using the official payload as the input and making only the
AppImage container reproducible.

If you produce a source build, compare its `resources/app/dist` tree with the
official Flatpak's tree. Matching JavaScript bundles are a stronger signal
than matching an outer container hash.
