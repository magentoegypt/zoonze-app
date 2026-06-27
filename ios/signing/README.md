# iOS signing (manual — no fastlane match)

Drop **two files** here so CI can build a **signed ad-hoc IPA** (installable
over-the-air via AppsOnAir / Diawi on registered devices) without a separate
`match` repo:

| File | What it is | How to get it |
|---|---|---|
| `*.p12` | Your **Apple Distribution** certificate **with its private key** | Keychain Access (Mac) → your *Apple Distribution* cert → right-click → **Export** as `.p12`, set a password. (Or create the cert at developer.apple.com → Certificates, then export.) |
| `*.mobileprovision` | An **ad-hoc** provisioning profile for `com.zoonze.shop` that includes your test devices' **UDIDs** | developer.apple.com → Profiles → **+** → *Ad Hoc* → pick the app id + distribution cert + devices → download |

The exact filenames don't matter — the build picks the first `*.p12` and first
`*.mobileprovision` here and reads the team id, bundle id and profile name from
the profile automatically.

## The one secret

Add the `.p12` password as a GitHub Actions secret:

- **`IOS_P12_PASSWORD`** — the password you set when exporting the `.p12`.

That's it — no `MATCH_*` / `APP_STORE_CONNECT_*` secrets needed for the ad-hoc
IPA. With the two files here **and** `IOS_P12_PASSWORD` set, every push to `main`
produces a signed `ipa-prod` (otherwise it falls back to an **unsigned** IPA).

## ⚠️ Security note

The `.p12` contains your **private key**. It's committed here (this is a private
repo) but is **password-protected**, and the password lives only in the GitHub
secret — never in git. If you'd rather not commit the key at all, store the
`.p12` as a base64 secret instead and we can decode it in CI; ask and we'll wire
that variant.

To revoke: delete the cert at developer.apple.com and remove the files here.
