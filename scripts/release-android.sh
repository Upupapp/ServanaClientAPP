#!/usr/bin/env bash
#
# Build, sign and verify the Android release. Run on a developer machine.
#
# ## Why this is a script and not a workflow
#
# It used to be the `release-android` job of `.github/workflows/flutter-ci.yml`.
# That workflow is deleted: this platform runs no CI on any repository, and
# GitHub Actions credit is not being topped up. Every check below is that job's,
# with the reasoning that put it there — a release job is usually the only
# written record of how an app is actually signed and shipped, and several of
# these checks exist because their absence already shipped a broken release.
#
# ## Secrets come from the environment now
#
# They were Actions repository secrets. Export them in the calling shell, or put
# them in a file you source and never commit. The NAMES are unchanged:
#
#   CM_KEYSTORE_BASE64          the upload keystore, `base64 -w0 upload-keystore.jks`
#   CM_KEYSTORE_PASSWORD
#   CM_KEY_ALIAS
#   CM_KEY_PASSWORD
#   GOOGLE_MAPS_API_KEY_ANDROID or GOOGLE_MAPS_API_KEY
#
# Optional, each enabling one distribution step:
#
#   FIREBASE_SERVICE_ACCOUNT    JSON, enables App Distribution
#   TESTER_GROUPS               group ALIASES, comma-separated (default: external)
#   RELEASE_NOTES               what testers should look at
#   PUBLISH_RELEASE=1           also upload to a GitHub Release via `gh`
#
# `gh release` is the GitHub CLI, not Actions. It starts no run and bills no
# minutes; it is only a way to store an artifact somewhere addressable by tag.

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

fail() { echo "ERROR: $*" >&2; exit 1; }

# ── Required secrets, checked before anything expensive ──────────────────────
# The build sets CM_KEYSTORE_PATH unconditionally, so an unset CM_KEYSTORE_BASE64
# does NOT fall back to a debug key — it fails deep inside Gradle with a keystore
# error naming neither the secret nor this script. Checked here, in milliseconds.
missing=""
[ -z "${CM_KEYSTORE_BASE64:-}" ]   && missing="$missing CM_KEYSTORE_BASE64"
[ -z "${CM_KEYSTORE_PASSWORD:-}" ] && missing="$missing CM_KEYSTORE_PASSWORD"
[ -z "${CM_KEY_ALIAS:-}" ]         && missing="$missing CM_KEY_ALIAS"
[ -z "${CM_KEY_PASSWORD:-}" ]      && missing="$missing CM_KEY_PASSWORD"
# Not a signing secret, but it fails WORSE than one. The build injects this over
# the strings.xml placeholder; unset, the old inline `sed` wrote an EMPTY key,
# the build went green, and the release shipped
# com.google.android.geo.API_KEY="" — booking tracking maps render as a grey
# rectangle on every device, with no error in any log.
if [ -z "${GOOGLE_MAPS_API_KEY_ANDROID:-}" ] && [ -z "${GOOGLE_MAPS_API_KEY:-}" ]; then
  missing="$missing GOOGLE_MAPS_API_KEY_ANDROID(or GOOGLE_MAPS_API_KEY)"
fi
[ -n "$missing" ] && fail "missing Android release secrets:$missing"

# ── Keystore ─────────────────────────────────────────────────────────────────
# A truncated or wrongly-encoded secret decodes to SOMETHING, and Gradle only
# discovers it is not a keystore after the whole app has compiled. keytool
# answers immediately.
KEYSTORE="${KEYSTORE_PATH:-/tmp/upload-keystore.jks}"
echo "-> keystore"
printf '%s' "$CM_KEYSTORE_BASE64" | base64 --decode > "$KEYSTORE"
[ -s "$KEYSTORE" ] || fail "CM_KEYSTORE_BASE64 decoded to an empty file."
keytool -list -keystore "$KEYSTORE" -storepass "$CM_KEYSTORE_PASSWORD" > /dev/null 2>&1 \
  || fail "the decoded keystore is unreadable: CM_KEYSTORE_BASE64 is not a valid base64 JKS, or CM_KEYSTORE_PASSWORD does not open it."
echo "   keystore decoded and opened."

# ── The Maps placeholders must still BE placeholders ─────────────────────────
# If one is already gone, a real key was committed — worth failing over, since
# it would ship a live Maps key in the repository. Both platforms are checked:
# checking only strings.xml meant a key committed into Info.plist passed
# unremarked.
echo "-> maps placeholders"
for f in android/app/src/main/res/values/strings.xml ios/Runner/Info.plist; do
  grep -q REPLACE_WITH_GOOGLE_MAPS_API_KEY "$f" \
    || fail "the Google Maps placeholder is missing from $f. A real key may have been committed; it must stay a placeholder and be substituted at build time."
done

# ── Version, from ONE source ─────────────────────────────────────────────────
# android/app/build.gradle reads flutter.versionCode out of local.properties and
# this step overwrites that file — so a hardcoded value here silently WINS over
# pubspec. It was once pinned to 35, so every release produced versionCode 35
# and Play rejected the second and every later upload as a duplicate. Bumping
# pubspec had no effect, which was the confusing part.
echo "-> version"
VERSION=$(grep -m1 '^version:' pubspec.yaml | sed 's/^version:[[:space:]]*//' | tr -d '\r')
VERSION_NAME="${VERSION%%+*}"
VERSION_CODE="${VERSION##*+}"
if [ -z "$VERSION_CODE" ] || [ "$VERSION_CODE" = "$VERSION" ]; then
  fail "pubspec.yaml version must be 'name+code', got '$VERSION'"
fi
echo "   versionName=$VERSION_NAME versionCode=$VERSION_CODE"

: "${ANDROID_SDK_ROOT:=${ANDROID_HOME:-}}"
[ -n "$ANDROID_SDK_ROOT" ] || fail "ANDROID_SDK_ROOT/ANDROID_HOME is not set."
[ -n "${FLUTTER_ROOT:-}" ] || FLUTTER_ROOT="$(dirname "$(dirname "$(command -v flutter)")")"

{
  echo "sdk.dir=$ANDROID_SDK_ROOT"
  echo "flutter.sdk=$FLUTTER_ROOT"
  echo "flutter.versionName=$VERSION_NAME"
  echo "flutter.versionCode=$VERSION_CODE"
} > android/local.properties

# ── Build ────────────────────────────────────────────────────────────────────
echo "-> pub get"
flutter pub get < /dev/null

# `--require` makes a missing key a build FAILURE. This was an inline `sed -i`
# inside the build step, Android-only, and unable to fail.
echo "-> inject maps key"
dart run tool/inject_maps_key.dart --require < /dev/null

export CM_KEYSTORE_PATH="$KEYSTORE"

echo "-> build AAB"
flutter build appbundle --release \
  --dart-define=API_BASE_URL=https://api.servana.com.ph \
  --dart-define=BRAND=servana \
  --dart-define=MOCK_BACKEND=false \
  --obfuscate \
  --split-debug-info=build/debug-info < /dev/null

# ── Verify the AAB signature ─────────────────────────────────────────────────
# apksigner is APK-only, so the AAB is verified with jarsigner. `jarsigner
# -verify` prints "jar is unsigned" and still EXITS 0, so the bare command
# verified nothing. Assert on the output, and re-assert the signer, so a build
# signed with the WRONG key is caught here rather than by Play.
echo "-> verify AAB signature"
AAB=build/app/outputs/bundle/release/app-release.aab
out=$(jarsigner -verify -verbose:summary -certs "$AAB" 2>&1) || true
echo "$out" | tail -25
echo "$out" | grep -q "jar verified" \
  || fail "AAB is NOT signed. jarsigner did not report 'jar verified'."
echo "$out" | grep -qi "CN=Servana Client" \
  || fail "AAB is signed, but not by the expected upload certificate."
echo "   AAB signed by the expected upload key."

# The mapping file is overwritten by the APK build below, and a release without
# its mapping cannot have a crash report symbolicated.
echo "-> preserve the AAB obfuscation mapping"
mkdir -p build/aab-mapping
cp build/app/outputs/mapping/release/mapping.txt build/aab-mapping/mapping.txt

echo "-> build APK"
flutter build apk --release \
  --dart-define=API_BASE_URL=https://api.servana.com.ph \
  --dart-define=BRAND=servana \
  --dart-define=MOCK_BACKEND=false \
  --obfuscate \
  --split-debug-info=build/debug-info-apk < /dev/null

echo "-> verify APK signature"
APK=build/app/outputs/flutter-apk/app-release.apk
APKSIGNER=$(find "$ANDROID_SDK_ROOT/build-tools" -name 'apksigner*' -type f 2>/dev/null | sort -V | tail -1)
[ -n "$APKSIGNER" ] || fail "apksigner not found under $ANDROID_SDK_ROOT/build-tools"
"$APKSIGNER" verify --verbose --print-certs "$APK" | tee /tmp/apksig.txt
grep -qi "CN=Servana Client" /tmp/apksig.txt \
  || fail "APK is not signed by the expected upload certificate."
# Android 11+ refuses to install an APK without a v2 signature.
grep -q "(APK Signature Scheme v2): true" /tmp/apksig.txt \
  || fail "APK lacks a v2 signature; Android 11+ will refuse to install it."
echo "   APK signed by the expected upload key, with a v2 signature."

sha256sum "$AAB" > "$AAB.sha256"
sha256sum "$APK" > "$APK.sha256"

# ── Distribution, both optional ──────────────────────────────────────────────
if [ -n "${FIREBASE_SERVICE_ACCOUNT:-}" ]; then
  echo "-> Firebase App Distribution"
  # Written with a restrictive umask and deleted in a trap, so the credential
  # never outlives this block even if a command below fails.
  umask 077
  printf '%s' "$FIREBASE_SERVICE_ACCOUNT" > /tmp/fb-sa.json
  trap 'rm -f /tmp/fb-sa.json' EXIT
  # Not a secret: this ID is in android/app/google-services.json, which is
  # committed, and it ships inside every APK.
  FIREBASE_APP_ID='1:320379709991:android:c3ec0648a70fb5081bfc02'
  # The group ALIAS, which Firebase shows in monospace beside the display name.
  # "External" is the name, `external` is the alias; passing the name fails with
  # "group not found".
  GOOGLE_APPLICATION_CREDENTIALS=/tmp/fb-sa.json \
  firebase appdistribution:distribute "$APK" \
    --app "$FIREBASE_APP_ID" \
    --groups "${TESTER_GROUPS:-external}" \
    --release-notes "${RELEASE_NOTES:-$VERSION_NAME ($VERSION_CODE)}"
else
  echo "-> Firebase App Distribution SKIPPED (FIREBASE_SERVICE_ACCOUNT unset)"
fi

if [ "${PUBLISH_RELEASE:-0}" = "1" ]; then
  echo "-> GitHub Release"
  TAG="build-${VERSION_CODE}"
  TITLE="${VERSION_NAME} (${VERSION_CODE})"
  # Re-runs at the same versionCode must not fail here.
  if gh release view "$TAG" > /dev/null 2>&1; then
    echo "   release $TAG exists — replacing its assets."
    gh release upload "$TAG" "$AAB" "$AAB.sha256" "$APK" "$APK.sha256" --clobber
  else
    gh release create "$TAG" "$AAB" "$AAB.sha256" "$APK" "$APK.sha256" \
      --title "$TITLE" --notes "${RELEASE_NOTES:-Release $TITLE}"
  fi
else
  echo "-> GitHub Release SKIPPED (PUBLISH_RELEASE unset)"
fi

echo
echo "== release built and verified: $VERSION_NAME ($VERSION_CODE) =="
echo "   AAB $AAB"
echo "   APK $APK"
echo "   mapping build/aab-mapping/mapping.txt — keep it, or crashes cannot be symbolicated"
