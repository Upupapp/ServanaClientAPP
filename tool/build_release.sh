#!/usr/bin/env bash
#
# Release build wrapper that CANNOT leave the Maps key on disk.
#
# The key is injected into a TRACKED file (android/app/src/main/res/values/
# strings.xml) and has to be removed again afterwards. Doing that with a
# trailing `git checkout --` is not safe: on 2026-08-11 a build was
# interrupted after injection and before the restore, and the live key sat
# uncommitted in the working tree until a sweep happened to catch it. An
# interrupt, a failed Gradle run or a killed terminal all produce the same
# result.
#
# `trap ... EXIT` runs on normal exit, on error, and on SIGINT/SIGTERM, so
# the restore happens whatever kills the build. The trap is installed BEFORE
# the injection, never after — installing it afterwards leaves the same hole
# for the window in between.
#
# Usage:
#   tool/build_release.sh apk [--target-platform android-x64]
#   tool/build_release.sh appbundle
set -euo pipefail

STRINGS="android/app/src/main/res/values/strings.xml"
PLACEHOLDER="REPLACE_WITH_GOOGLE_MAPS_API_KEY"
: "${GOOGLE_MAPS_API_KEY_ANDROID:?set GOOGLE_MAPS_API_KEY_ANDROID before building}"

cd "$(dirname "$0")/.."

restore() {
  local rc=$?
  if [ -f "$STRINGS" ] && ! grep -q "$PLACEHOLDER" "$STRINGS"; then
    git checkout -- "$STRINGS" 2>/dev/null || true
    echo "[build_release] restored $STRINGS"
  fi
  # Fail loudly rather than silently shipping a key: if the placeholder is
  # still absent after the restore, the tree is dirty and someone must look.
  if [ -f "$STRINGS" ] && ! grep -q "$PLACEHOLDER" "$STRINGS"; then
    echo "[build_release] FATAL: $STRINGS still contains an injected key" >&2
    exit 1
  fi
  exit $rc
}
trap restore EXIT INT TERM

TARGET="${1:-appbundle}"; shift || true

dart run tool/inject_maps_key.dart

flutter build "$TARGET" --release \
  --dart-define=API_BASE_URL=https://api.servana.com.ph \
  --dart-define=BRAND=servana \
  --dart-define=MOCK_BACKEND=false \
  --obfuscate --split-debug-info=build/debug-info \
  "$@"

# Belt and braces: prove the key is gone before the trap even runs, so a
# green build never coexists with a dirty tree.
#
# Check the INJECTED key specifically, not /AIzaSy/. The broad pattern was a
# false positive on its first real run: android/app/google-services.json and
# ios/Runner/GoogleService-Info.plist are committed Firebase client config and
# legitimately contain AIzaSy... values. A guard that fails on a correct tree
# gets disabled, which is worse than no guard.
git checkout -- "$STRINGS"
if ! grep -q "$PLACEHOLDER" "$STRINGS"; then
  echo "[build_release] FATAL: $STRINGS does not hold the placeholder" >&2
  exit 1
fi
if git grep -qI "$GOOGLE_MAPS_API_KEY_ANDROID" -- . ; then
  echo "[build_release] FATAL: the injected Maps key is in a tracked file" >&2
  exit 1
fi
echo "[build_release] OK — key restored, tree clean"
