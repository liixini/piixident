#!/bin/bash
# Shared library: environment variables, config helpers, command checks, compositor detection

# Standard paths (XDG-aware)
export SKWD_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/skwd"
export SKWD_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/skwd"
export SKWD_RUNTIME="${XDG_RUNTIME_DIR:-/tmp}/skwd"
export SKWD_INSTALL="${SKWD_INSTALL:-$SKWD_CONFIG}"
export SKWD_CFG="$SKWD_CONFIG/data/config.json"
export SKWD_MATUGEN_CONFIG="$SKWD_CACHE/matugen-config.toml"

# Ensure runtime and cache directories exist
mkdir -p "$SKWD_RUNTIME" 2>/dev/null
mkdir -p "$SKWD_CACHE" 2>/dev/null
mkdir -p "$SKWD_CACHE/wallpaper" 2>/dev/null
mkdir -p "$SKWD_CACHE/app-launcher" 2>/dev/null

# Seed cache files that QML components expect
[ -f "$SKWD_CACHE/bar-state" ] || echo "true" > "$SKWD_CACHE/bar-state" 2>/dev/null
[ -f "$SKWD_CACHE/colors.json" ] || echo '{}' > "$SKWD_CACHE/colors.json" 2>/dev/null
[ -f "$SKWD_CACHE/wallpaper/tags.json" ] || echo '{}' > "$SKWD_CACHE/wallpaper/tags.json" 2>/dev/null
[ -f "$SKWD_CACHE/wallpaper/colors.json" ] || echo '{}' > "$SKWD_CACHE/wallpaper/colors.json" 2>/dev/null
[ -f "$SKWD_CACHE/wallpaper/matugen-colors.json" ] || echo '{}' > "$SKWD_CACHE/wallpaper/matugen-colors.json" 2>/dev/null
[ -f "$SKWD_CACHE/app-launcher/freq.json" ] || echo '{}' > "$SKWD_CACHE/app-launcher/freq.json" 2>/dev/null

# Read a jq path from config.json, expand ~ to $HOME
cfg_get() {
  local val
  val=$(jq -r "$1" "$SKWD_CFG" 2>/dev/null)
  [ "$val" = "null" ] && val=""
  echo "${val/#\~/$HOME}"
}

# Abort if any listed commands are missing
require_cmd() {
  local missing=()
  for cmd in "$@"; do
    command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
  done
  if [ ${#missing[@]} -gt 0 ]; then
    echo "skwd: missing required commands: ${missing[*]}" >&2
    echo "  Install them and try again." >&2
    exit 1
  fi
}

# Silent command existence check
has_cmd() {
  command -v "$1" >/dev/null 2>&1
}

# Auto-detect compositor from config or running process
detect_compositor() {
  local configured
  configured=$(jq -r '.compositor // ""' "$SKWD_CFG" 2>/dev/null)
  if [ -n "$configured" ] && [ "$configured" != "null" ]; then
    echo "$configured"
    return
  fi
  if has_cmd niri && pgrep -x niri >/dev/null 2>&1; then
    echo "niri"
  elif [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
    echo "hyprland"
  elif [ -n "$SWAYSOCK" ]; then
    echo "sway"
  else
    echo "unknown"
  fi
}

export SKWD_COMPOSITOR="${SKWD_COMPOSITOR:-$(detect_compositor)}"

# GPU vendor detection (nvidia/amd/intel)
detect_gpu() {
  if has_cmd nvidia-smi; then
    echo "nvidia"
  elif [ -d /sys/class/drm/card0/device ] && grep -qi amd /sys/class/drm/card0/device/vendor 2>/dev/null; then
    echo "amd"
  elif [ -d /sys/class/drm/card0/device ] && grep -qi intel /sys/class/drm/card0/device/vendor 2>/dev/null; then
    echo "intel"
  else
    echo "unknown"
  fi
}
