"""Shared config loader for piixident scripts."""
import json
from pathlib import Path

# Config file path
CONFIG_PATH = Path.home() / ".config/piixident/data/config.json"

_config = None

# Singleton JSON loader with error fallback
def load_config() -> dict:
    global _config
    if _config is not None:
        return _config
    try:
        _config = json.loads(CONFIG_PATH.read_text())
    except (FileNotFoundError, json.JSONDecodeError):
        _config = {}
    return _config

# Dot-separated config path accessor
def get(path: str, default=None):
    """Get a config value by dot-separated path, e.g. 'ollama.url'."""
    cfg = load_config()
    for key in path.split("."):
        if isinstance(cfg, dict):
            cfg = cfg.get(key)
        else:
            return default
        if cfg is None:
            return default
    return cfg

# Path expansion helper
def expand_path(path: str) -> str:
    """Expand ~ in a path string."""
    return str(Path(path).expanduser())

# Typed config accessors
def ollama_url() -> str:
    return get("ollama.url", "http://localhost:11434")

def ollama_model() -> str:
    return get("ollama.model", "gemma3:4b")

def wallpaper_dir() -> Path:
    return Path(expand_path(get("paths.wallpaper", "~/wallpaper")))

def steam_dir() -> Path:
    return Path(expand_path(get("paths.steam", "~/.local/share/Steam")))

def we_workshop_dir() -> str:
    return expand_path(get("paths.steamWorkshop", ""))

def we_assets_dir() -> str:
    return expand_path(get("paths.steamWeAssets", ""))

def wifi_interface() -> str:
    return get("components.bar.wifi.interface", "wlan0")

def matugen_scheme() -> str:
    return get("matugen.schemeType", "scheme-fidelity")

def kde_color_scheme() -> str:
    return get("matugen.kdeColorScheme", "PiixidentMatugen")
