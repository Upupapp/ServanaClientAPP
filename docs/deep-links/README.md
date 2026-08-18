# Deep links — hosting the association files

Both files in `well-known/` are ready to serve. Neither can be completed or
deployed from this repository.

## Where they go

| file | URL | content type |
| --- | --- | --- |
| `assetlinks.json` | `https://<host>/.well-known/assetlinks.json` | `application/json` |
| `apple-app-site-association` | `https://<host>/.well-known/apple-app-site-association` | `application/json` |

For each of `servana.com.ph`, `www.servana.com.ph`, `app.servana.com.ph`.

**HTTPS, no redirect, correct content type.** Serve the Apple file with **no
extension** — that single detail is the most common cause of a silent Universal
Link failure, and it fails silently, which is the worst way for it to fail.

⚠️ **Check the well-known path is not shadowed before deploying.** A wildcard
route has eaten a new sibling on this backend before.

## The Android fingerprints are placeholders on purpose

`assetlinks.json` carries `REPLACE_WITH_*` because the real values come from the
signing keys, and TAB 13 established R8 only against a throwaway key.

Two fingerprints are needed, and shipping only one is the usual mistake:

1. **Play app-signing certificate** — Play Console → Release → Setup → App
   signing. This is what Play actually re-signs with, so it is what a user's
   device sees.
2. **Upload key certificate** — what CI signs with. Needed so internal-testing
   and locally-installed builds verify too.

Get the upload-key value with:

```bash
keytool -list -v -keystore <upload-keystore> -alias <alias> | grep SHA256
```

Strip the colons? **No** — Google's format keeps them uppercase and colon-
separated.

## Verifying, rather than assuming a tap worked

```bash
# Android: ask the platform, do not infer from a tap
adb shell pm get-app-links com.servana.serviceclient
# expect: servana.com.ph: verified

# Force a re-verification after publishing the file
adb shell pm verify-app-links --re-verify com.servana.serviceclient
```

iOS: open a link from **Mail and from Notes** on a real device, cold and warm.
Safari's address bar deliberately does not trigger Universal Links, so testing
there and concluding it is broken is the classic false negative.

## What the app does before the files exist

Nothing breaks. Android verification fails, iOS does not claim the domain, and
links open in the browser. The failure direction is safe, which is why the
client half ships first.

## Still manual

- Hosting both files (**M4.3**)
- Associated Domains capability on App ID `com.servana.client` (**M4.4**)
- Filling both Android fingerprints (**M4.1**)
- On-device verification, cold and warm (**M4.14**)
