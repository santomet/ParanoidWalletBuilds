# Coin Wallet PIN troubleshooting

This page documents the PIN behavior that is easy to mistake for a broken
build. The PIN code is implemented by Coin Wallet itself; the AppImage is a
repack of the official payload.

## "Set a PIN" fails with "Error! Please check your internet connection and try again."

Coin Wallet's PIN is **not purely local**. During setup the app sends a PIN
hash to `https://coin.space/api/v4/register` and receives device and wallet
tokens. If that request fails, the PIN cannot be completed.

This is upstream behavior, not something the AppImage adds. The official
Flatpak behaves the same way. The same applies at unlock time: the PIN is
exchanged for a server token, so login needs network access.

Check whether the API is reachable from the same machine:

```bash
curl -sS -o /dev/null -w '%{http_code}\n' https://coin.space/api/v4/register
```

A `4xx`/`405` response means the host is reachable (the method is wrong, which
is fine for this check). A connection error, timeout, or TLS error means the
app cannot complete PIN setup.

Common causes:

- offline machine,
- firewall/DNS blocking `coin.space` or `*.coin.space`,
- VPN/Tor setup that does not route the app,
- a minimal Linux install without NSS (`libnss3`, `libnspr4`), which Electron
  needs for HTTPS. Install the distribution's NSS packages and retry.

## The PIN is exactly four digits

The keypad accepts four digits. There is no "confirm PIN" step: the first four
digits are used, and extra digits are ignored. If you type six digits, the PIN
is the first four.

## I forgot the PIN, or entered it wrong three times

After three wrong PIN entries, Coin Wallet's server erases the token that
decrypts the local device seed. The old PIN can no longer unlock the wallet.

Recovery:

1. On the unlock screen, choose **Log out**.
2. Choose **Open existing wallet**.
3. Enter your 12/15/18/21/24-word passphrase.
4. Set a new 4-digit PIN.

The passphrase is the only recovery path. The PIN is not a backup.

## I want to change the PIN

The desktop app has no "Change PIN" item. **Settings → PIN** only contains the
**High security** toggle (and biometrics on supported mobile builds). To change
the PIN, log out and restore the wallet with the passphrase, then set a new PIN.

## Wrong PIN gives no error message

The dots shake and clear when the server rejects a PIN, but the desktop build
does not display a textual "wrong PIN" message. After three failures the server
token is removed, so do not keep guessing. Use the passphrase recovery above.

## The wallet opens but balances/prices do not load

This usually means the app cannot reach `coin.space` over HTTPS. Check the same
`curl` command above. On minimal distributions install NSS. If you are behind a
restrictive network, use a network where the API is reachable; the wallet's
server-assisted PIN flow does not work fully offline.
