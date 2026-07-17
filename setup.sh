#!/usr/bin/env sh
set -eu

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"

detect_os() {
  case "$(uname -s)" in
    Linux) echo "linux" ;;
    Darwin) echo "macos" ;;
    *) echo "unknown" ;;
  esac
}

detect_arch() {
  case "$(uname -m)" in
    x86_64) echo "x86_64" ;;
    aarch64|arm64) echo "aarch64" ;;
    *) echo "unknown" ;;
  esac
}

is_wsl() {
  if [ "$(detect_os)" != "linux" ]; then
    return 1
  fi
  if [ -n "${WSL_DISTRO_NAME:-}" ]; then
    return 0
  fi
  if [ -r /proc/version ] && grep -qi microsoft /proc/version 2>/dev/null; then
    return 0
  fi
  return 1
}

install_swift_toolchain() {
  os="$(detect_os)"
  tmp_dir="$(mktemp -d)"
  if [ "$os" = "linux" ]; then
    ( cd "$tmp_dir" && \
      curl -O "https://download.swift.org/swiftly/linux/swiftly-$(uname -m).tar.gz" && \
      tar zxf "swiftly-$(uname -m).tar.gz" && \
      ./swiftly init --quiet-shell-followup )
    # shellcheck disable=SC1091
    . "${SWIFTLY_HOME_DIR:-$HOME/.local/share/swiftly}/env.sh"
  elif [ "$os" = "macos" ]; then
    ( cd "$tmp_dir" && \
      curl -O "https://download.swift.org/swiftly/darwin/swiftly.pkg" && \
      installer -pkg swiftly.pkg -target CurrentUserHomeDirectory && \
      "$HOME/.swiftly/bin/swiftly" init --quiet-shell-followup )
    # shellcheck disable=SC1091
    . "${SWIFTLY_HOME_DIR:-$HOME/.swiftly}/env.sh"
  else
    echo "Unsupported OS for automatic Swift install: $os" >&2
    return 1
  fi
  rm -rf "$tmp_dir"
  hash -r 2>/dev/null || true
}

ensure_swift() {
  if command -v swift >/dev/null 2>&1; then
    echo "Swift already installed: $(swift --version 2>&1 | head -1)"
    return 0
  fi
  echo "Swift not found — installing via swiftly..."
  install_swift_toolchain
  if ! command -v swift >/dev/null 2>&1; then
    echo "Swift install did not complete. Follow the manual instructions at https://www.swift.org/install/ and re-run this script." >&2
    return 1
  fi
  echo "Swift installed: $(swift --version 2>&1 | head -1)"
}

install_xtool_binary() {
  target_dir="$1"
  os="$(detect_os)"
  arch="$(detect_arch)"
  mkdir -p "$target_dir"
  if [ "$os" = "linux" ]; then
    if [ "$arch" = "unknown" ]; then
      echo "Unsupported architecture for xtool auto-install: $(uname -m)" >&2
      return 1
    fi
    url="https://github.com/xtool-org/xtool/releases/latest/download/xtool-${arch}.AppImage"
    curl -fL -o "$target_dir/xtool" "$url"
    chmod +x "$target_dir/xtool"
  elif [ "$os" = "macos" ]; then
    url="https://github.com/xtool-org/xtool/releases/latest/download/xtool.app.zip"
    curl -fL -o "$target_dir/xtool.app.zip" "$url"
    ( cd "$target_dir" && unzip -q -o xtool.app.zip )
    ln -sf "$target_dir/xtool.app/Contents/MacOS/xtool" "$target_dir/xtool"
  else
    echo "Unsupported OS for xtool auto-install: $os" >&2
    return 1
  fi
  if [ ! -x "$target_dir/xtool" ]; then
    echo "xtool install failed — no executable found at $target_dir/xtool" >&2
    return 1
  fi
}

ensure_xtool() {
  target_dir="$1"
  if command -v xtool >/dev/null 2>&1; then
    echo "xtool already installed: $(xtool --version 2>&1)"
    return 0
  fi
  echo "xtool not found — downloading to $target_dir..."
  install_xtool_binary "$target_dir"
  echo "xtool installed to $target_dir/xtool"
}

apple_setup_is_configured() {
  xtool auth status 2>&1 | grep -q "^Logged in\." && \
  xtool sdk status 2>&1 | grep -q "^Installed at "
}

ensure_apple_setup() {
  if apple_setup_is_configured; then
    echo "Apple auth and Darwin SDK already configured."
    return 0
  fi
  cat <<'EOF'
xtool needs a one-time Apple setup that only you can do (needs your own Apple ID):

1. Download Xcode.xip from https://developer.apple.com/download/ (free Apple ID, any browser -- you do NOT need to install or run Xcode, just download the .xip)
2. Note: the Xcode and Swift versions must match, or xtool will fail with a cryptic "cannot find type 'Swift' in scope" error. Swift 6.2 pairs with the Xcode 26.x line.
3. Once downloaded, press Enter and this script will run `xtool setup`, which will interactively ask for your Apple ID login and the path to the .xip you just downloaded.

Press Enter when ready...
EOF
  read -r _
  xtool setup
  if apple_setup_is_configured; then
    echo "Apple auth and Darwin SDK configured successfully."
  else
    echo "xtool setup did not finish successfully. Run 'xtool auth status' and 'xtool sdk status' yourself to see what's missing, then re-run this script." >&2
    return 1
  fi
}

ensure_device_paired() {
  attempt=1
  max_attempts=2
  while [ "$attempt" -le "$max_attempts" ]; do
    echo "Connect your iPhone via USB, unlock it, and tap 'Trust This Computer' if prompted."
    printf 'Press Enter when your phone is connected and trusted...'
    read -r _
    if idevice_id -l 2>/dev/null | grep -q .; then
      echo "Device detected: $(idevice_id -l)"
      return 0
    fi
    echo "No device detected yet."
    attempt=$((attempt + 1))
  done
  echo "Still no device detected after $max_attempts attempts. Troubleshooting:" >&2
  echo "  - Run 'idevicepair validate' to check pairing status" >&2
  echo "  - Try unplugging and replugging the USB cable" >&2
  echo "  - Make sure the phone is unlocked when you connect it" >&2
  return 1
}

main() {
  echo "main not yet implemented"
}

if [ "${SETUP_SH_SOURCED:-0}" != "1" ]; then
  main "$@"
fi
