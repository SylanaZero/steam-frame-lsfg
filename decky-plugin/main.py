import os
import glob
from pathlib import Path
try:
    import tomllib  # Python 3.11+
except ImportError:
    try:
        import toml as tomllib
    except ImportError:
        tomllib = None

class Plugin:
    def __init__(self):
        self.config_dir = Path(os.environ.get("XDG_CONFIG_HOME", os.path.expanduser("~/.config"))) / "steam-frame-lsfg"
        self.config_dir.mkdir(parents=True, exist_ok=True)
        (self.config_dir / "profiles").mkdir(exist_ok=True)
        self.config_file = self.config_dir / "config.toml"

    async def _main(self):
        pass

    async def _unload(self):
        pass

    async def get_status(self) -> dict:
        """Returns whether lsfg-vk.dll is available and the current global settings."""
        dll_found = False
        dll_path = ""
        
        search_paths = [
            os.path.expanduser("~/.local/share/steam-frame-lsfg/lib/lsfg-vk.dll"),
            os.path.expanduser("~/.steam/steam/steamapps/common/Lossless Scaling/lsfg-vk.dll"),
            os.path.expanduser("~/.local/share/Steam/steamapps/common/Lossless Scaling/lsfg-vk.dll"),
            *glob.glob("/run/media/*/steamapps/common/Lossless Scaling/lsfg-vk.dll"),
            *glob.glob("/run/media/*/*/steamapps/common/Lossless Scaling/lsfg-vk.dll"),
        ]
        
        for path in search_paths:
            if os.path.isfile(path):
                dll_found = True
                dll_path = path
                break

        aurora_icd = Path(os.environ.get("XDG_DATA_HOME", os.path.expanduser("~/.local/share"))) / "steam-frame-lsfg" / "drivers" / "freedreno_icd.aarch64.json"
        aurora_found = aurora_icd.exists()

        cfg = await self.get_config(0)
        return {
            "dll_found": dll_found,
            "dll_path": dll_path,
            "aurora_found": aurora_found,
            "config": cfg,
            "hardware": "Qualcomm Snapdragon 8 Gen 3 (Adreno 750 / Turnip)"
        }

    async def get_config(self, app_id: int) -> dict:
        """Retrieves configuration for a specific AppID or the global default."""
        target_file = self.config_file
        if app_id and app_id > 0:
            profile_file = self.config_dir / "profiles" / f"{app_id}.toml"
            if profile_file.exists():
                target_file = profile_file

        data = {
            "enabled": True,
            "multiplier": 2,
            "flow_scale": 0.75,
            "performance_mode": True,
            "sync_to_display": True,
        }

        if target_file.exists() and tomllib:
            try:
                with open(target_file, "rb") as f:
                    parsed = tomllib.load(f)
                    if "framegen" in parsed:
                        data.update(parsed["framegen"])
                    else:
                        data.update(parsed)
            except Exception as e:
                print(f"[SteamFrame-LSFG] Error parsing {target_file}: {e}")

        return data

    async def save_config(self, app_id: int, settings: dict) -> bool:
        """Saves configuration for an app or globally."""
        try:
            target_file = self.config_file
            if app_id and app_id > 0:
                target_file = self.config_dir / "profiles" / f"{app_id}.toml"

            lines = [
                f"# Steam Frame LSFG {'Profile for AppID ' + str(app_id) if app_id else 'Global Config'}\n",
                f"enabled = {'true' if settings.get('enabled', True) else 'false'}\n",
                f"multiplier = {int(settings.get('multiplier', 2))}\n",
                f"flow_scale = {float(settings.get('flow_scale', 0.75))}\n",
                f"performance_mode = {'true' if settings.get('performance_mode', True) else 'false'}\n",
                f"sync_to_display = {'true' if settings.get('sync_to_display', True) else 'false'}\n"
            ]

            with open(target_file, "w") as f:
                f.writelines(lines)
            return True
        except Exception as e:
            print(f"[SteamFrame-LSFG] Failed to write config: {e}")
            return False
