#!/usr/bin/env sh
set -eu

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
ANDROID_DIR="$REPO_ROOT/android"

ensure_android_sdk() {
  if [ -n "${ANDROID_HOME:-}" ] && [ -d "$ANDROID_HOME" ]; then
    echo "Android SDK found at $ANDROID_HOME"
    return 0
  fi
  cat <<'EOF'
No Android SDK found (ANDROID_HOME is not set, or doesn't point to a real directory).

This script doesn't install the Android SDK for you -- Android Studio's own SDK
Manager is the realistic way to get it:

1. Install Android Studio: https://developer.android.com/studio
2. Open it once, let it install the default SDK components
3. Find your SDK path in Android Studio: Settings > Languages & Frameworks > Android SDK
4. Set ANDROID_HOME to that path in your shell profile, e.g.:
     export ANDROID_HOME="$HOME/Android/Sdk"
5. Re-run this script.
EOF
  return 1
}

write_local_properties() {
  properties_file="$ANDROID_DIR/local.properties"
  if [ -f "$properties_file" ]; then
    echo "android/local.properties already exists, leaving it as-is."
    return 0
  fi
  echo "sdk.dir=$ANDROID_HOME" > "$properties_file"
  echo "Wrote $properties_file"
}

build_and_install_android() {
  if ! command -v adb >/dev/null 2>&1 || ! adb devices | grep -qE "device$|emulator"; then
    echo "No Android device or emulator detected via 'adb devices'."
    echo "Connect a device or start an emulator, then run:"
    echo "  cd android && ./gradlew installDebug"
    return 0
  fi
  ( cd "$ANDROID_DIR" && ./gradlew installDebug )
}

main() {
  ensure_android_sdk
  write_local_properties
  build_and_install_android
}

if [ "${SETUP_ANDROID_SH_SOURCED:-0}" != "1" ]; then
  main "$@"
fi
