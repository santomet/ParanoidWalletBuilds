# ParanoidWalletBuilds

## YOU SHOULD NOT TRUST THESE BUILDS!!!

These are unofficial builds of crypto wallets. They are published so that you
can inspect, reproduce, and compare them — **not** so that you can trust me.

**If you did not build it yourself, verify it yourself. If you cannot verify
it, do not use it for meaningful funds.**

I am not affiliated with any wallet vendor. These builds are not endorsed by
the upstream projects. They may be wrong, outdated, or malicious. The point is
to make the build process visible, not to ask for trust.

## Wallets

| Wallet | Version | Platform | Build type | Folder |
| --- | --- | --- | --- | --- |
| Coin Wallet (coin.space) | 6.31.0 | Linux x86_64 | Repackaged official Flatpak → AppImage | [coin.space](./coin.space/) |

`Build type` matters. A repackaged upstream binary is not an independent
source build. It can still be useful, but it does not prove that the binary
matches the source.

## Releases

- [Coin Wallet 6.31.0 — Linux x86_64 AppImage](https://github.com/santomet/ParanoidWalletBuilds/releases/tag/coin.space-v6.31.0)

## Verify a release

1. Download the release asset and `SHA256SUMS`.
2. Run `sha256sum -c SHA256SUMS`.
3. Compare the hash with the one in the release notes.
4. Read the wallet's folder README and rebuild it yourself.
5. Better: build the wallet from upstream source and compare.

A hash only proves you have the same file that was published. It does not
prove that the file is safe.

## Reproducibility

Each wallet folder documents:

- upstream version and URL,
- hashes of all inputs,
- exact build commands,
- hashes of the outputs,
- known limitations.

Where the build is reproducible, the folder says so. Where it is only a
repack, the folder says that too.

## License

The build scripts and documentation in this repository are MIT licensed.
The wallets themselves retain their upstream licenses.
