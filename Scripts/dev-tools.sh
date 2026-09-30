#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOOLS_DIR="$ROOT_DIR/.cache/dev-tools"
BIN_DIR="$TOOLS_DIR/bin"
DOWNLOAD_DIR="$TOOLS_DIR/downloads"
WORK_DIR=""
ERRORS=0
source "$ROOT_DIR/Scripts/dev-tools.env"

fail() {
  echo "dev-tools: $*" >&2
  exit 1
}

problem() {
  echo "error: $*" >&2
  ERRORS=$((ERRORS + 1))
}

cleanup() {
  if [ -n "$WORK_DIR" ]; then
    rm -rf "$WORK_DIR"
  fi
}

check_prerequisites() {
  local version major minor xcode_version
  if [ "$(uname -s)" != Darwin ]; then
    problem "macOS 15 or newer is required."
    return
  fi
  [ "$(uname -m)" = arm64 ] || problem "Use a native Apple Silicon terminal, without Rosetta."
  version="$(sw_vers -productVersion)"
  major="${version%%.*}"
  if [ "$major" -lt 15 ]; then
    problem "macOS 15 or newer is required; found $version."
  else
    echo "macOS: $version ($(uname -m))"
  fi

  if xcode_version="$(xcodebuild -version 2>/dev/null)"; then
    echo "$xcode_version"
    version="$(printf '%s\n' "$xcode_version" | awk '/^Xcode / { print $2 }')"
    major="${version%%.*}"
    [ "$major" -ge 16 ] || problem "Select Xcode 16 or newer; Xcode 15 does not include Swift 6.0."
  else
    problem "Install and select Xcode 16 with Swift 6.0; Command Line Tools alone are insufficient."
  fi

  if version="$(swift --version 2>/dev/null)"; then
    echo "$version"
    version="$(printf '%s\n' "$version" | sed -n 's/.*Swift version \([0-9.]*\).*/\1/p' | head -n 1)"
    IFS=. read -r major minor _ <<< "$version"
    if [ "${major:-0}" -lt 6 ] || { [ "${major:-0}" -eq 6 ] && [ "${minor:-0}" -lt 0 ]; }; then
      problem "Swift 6.0 or newer is required; select the Xcode 16 toolchain."
    fi
  else
    problem "Swift is unavailable; install and select Xcode 16."
  fi

  if version="$(xcrun --sdk macosx --show-sdk-version 2>/dev/null)"; then
    echo "macOS SDK: $version"
    major="${version%%.*}"
    [ "$major" -ge 15 ] || problem "The selected macOS SDK must be version 15 or newer."
  else
    problem "The selected Xcode has no usable macOS SDK."
  fi

  if version="$(python3 --version 2>/dev/null)"; then
    echo "$version"
  else
    problem "Python 3 is required for Dev install path checks and tooling tests."
  fi
}

tool_version() {
  case "$1" in
    swiftformat) "$2" --version ;;
    swiftlint) "$2" version ;;
  esac
}

check_tool() {
  local tool="$1" expected="$2" actual
  if actual="$(tool_version "$tool" "$BIN_DIR/$tool" 2>/dev/null)" && [ "$actual" = "$expected" ]; then
    echo "$tool: $actual ($BIN_DIR/$tool)"
  else
    problem "$tool $expected is missing from $BIN_DIR; run make setup."
  fi
}



check_signing() {
  local identity="${AEROFLOW_SIGNING_IDENTITY:-AeroFlow Dev}"
  if security find-identity -v -p codesigning 2>/dev/null | awk -v identity="$identity" '$2 == identity || index($0, "\"" identity "\"") { found = 1 } END { exit !found }'; then
    echo "Development signing identity: $identity"
  else
    echo "warning: No code-signing identity named \"$identity\". Dev will use ad-hoc signing; the optional local certificate helps retain permissions across rebuilds." >&2
  fi
}

print_paths() {
  local config_base="${XDG_CONFIG_HOME:-$HOME/.config}"
  local state_base="${XDG_STATE_HOME:-$HOME/.local/state}"
  local dev_app="${AEROFLOW_DEV_INSTALL_DIR:-$HOME/Applications}/${AEROFLOW_DEV_APP_NAME:-AeroFlow Dev}.app"
  local release_app="${AEROFLOW_RELEASE_APP:-/Applications/AeroFlow.app}" app
  case "$config_base" in /*) ;; *) config_base="$HOME/.config" ;; esac
  case "$state_base" in /*) ;; *) state_base="$HOME/.local/state" ;; esac
  echo "Development tools: $BIN_DIR"
  echo "Release settings: $config_base/aeroflow/settings.toml"
  echo "Dev settings: $config_base/aeroflow-dev/settings.toml"
  echo "Dev state: $state_base/aeroflow-dev"
  for app in "$dev_app" "$release_app"; do
    if [ -d "$app" ]; then
      echo "Installed app: $app"
    else
      echo "App not installed: $app"
    fi
  done
}

has_digest() {
  [ -f "$1" ] && [ "$(shasum -a 256 "$1" | awk '{print $1}')" = "$2" ]
}

download() {
  local url="$1" digest="$2" destination="$DOWNLOAD_DIR/$2.zip"
  if ! has_digest "$destination" "$digest"; then
    echo "Downloading $url" >&2
    curl --fail --location --silent --show-error --connect-timeout 15 --max-time 600 \
      "$url" --output "$WORK_DIR/download.zip" || fail "Download failed: $url"
    has_digest "$WORK_DIR/download.zip" "$digest" || fail "Downloaded archive checksum mismatch: $url"
    mv -f "$WORK_DIR/download.zip" "$destination"
  fi
  printf '%s\n' "$destination"
}

install_tool() {
  local tool="$1" expected="$2" url="$3" digest="$4" archive actual
  if actual="$(tool_version "$tool" "$BIN_DIR/$tool" 2>/dev/null)" && [ "$actual" = "$expected" ]; then
    return
  fi
  archive="$(download "$url" "$digest")"
  mkdir -p "$WORK_DIR/$tool"
  ditto -x -k "$archive" "$WORK_DIR/$tool"
  [ -f "$WORK_DIR/$tool/$tool" ] || fail "$tool archive did not contain the expected executable."
  chmod 755 "$WORK_DIR/$tool/$tool"
  actual="$(tool_version "$tool" "$WORK_DIR/$tool/$tool")"
  [ "$actual" = "$expected" ] || fail "$tool archive reports $actual; expected $expected."
  mv -f "$WORK_DIR/$tool/$tool" "$BIN_DIR/$tool"
}


case "${1:-doctor}" in
  setup)
    check_prerequisites
    true || exit 1
    mkdir -p "$BIN_DIR" "$DOWNLOAD_DIR"
    WORK_DIR="$(mktemp -d "$TOOLS_DIR/setup.XXXXXX")"
    trap cleanup EXIT
    install_tool swiftformat "$SWIFTFORMAT_VERSION" "https://github.com/nicklockwood/SwiftFormat/releases/download/$SWIFTFORMAT_VERSION/swiftformat.zip" "$AEROFLOW_SWIFTFORMAT_ZIP_SHA256"
    install_tool swiftlint "$SWIFTLINT_VERSION" "https://github.com/realm/SwiftLint/releases/download/$SWIFTLINT_VERSION/portable_swiftlint.zip" "$AEROFLOW_SWIFTLINT_ZIP_SHA256"
    check_tool swiftformat "$SWIFTFORMAT_VERSION"
    check_tool swiftlint "$SWIFTLINT_VERSION"
    check_signing
    print_paths
    true
    ;;
  doctor)
    check_prerequisites
    check_tool swiftformat "$SWIFTFORMAT_VERSION"
    check_tool swiftlint "$SWIFTLINT_VERSION"
    check_signing
    print_paths
    true
    ;;
  *)
    echo "Usage: Scripts/dev-tools.sh [setup|doctor]" >&2
    exit 64
    ;;
esac
