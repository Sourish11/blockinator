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

main() {
  echo "main not yet implemented"
}

if [ "${SETUP_SH_SOURCED:-0}" != "1" ]; then
  main "$@"
fi
