import os
import unittest
from pathlib import Path

# Support Python 3.11+ tomllib or fallback
try:
    import tomllib
except ImportError:
    try:
        import toml as tomllib
    except ImportError:
        tomllib = None

PROJECT_ROOT = Path(__file__).resolve().parent.parent

class TestSteamFrameLSFGConfig(unittest.TestCase):
    def setUp(self):
        self.config_dir = PROJECT_ROOT / "config"
        self.profiles_dir = self.config_dir / "profiles"

    def test_default_config_exists_and_valid(self):
        default_cfg = self.config_dir / "config.default.toml"
        self.assertTrue(default_cfg.exists(), "config.default.toml must exist")
        
        if tomllib:
            with open(default_cfg, "rb") as f:
                data = tomllib.load(f)
            self.assertIn("version", data)
            self.assertEqual(data["version"], 2)
            self.assertIn("global", data)
            self.assertIn("profile", data)
            
            fg = data["profile"][0]
            self.assertIn(fg["multiplier"], [2, 3, 4], "Multiplier must be 2, 3, or 4")
            self.assertTrue(0.5 <= fg["flow_scale"] <= 1.0, "Flow scale must be between 0.5 and 1.0")
            self.assertIsInstance(fg["performance_mode"], bool)

    def test_game_profiles_valid(self):
        self.assertTrue(self.profiles_dir.exists(), "Profiles directory must exist")
        profiles = list(self.profiles_dir.glob("*.toml"))
        self.assertGreater(len(profiles), 0, "At least one profile must exist")

        if tomllib:
            for p in profiles:
                with open(p, "rb") as f:
                    data = tomllib.load(f)
                self.assertIn("enabled", data, f"Profile {p.name} must have 'enabled'")
                self.assertIn("multiplier", data, f"Profile {p.name} must have 'multiplier'")
                self.assertIn("flow_scale", data, f"Profile {p.name} must have 'flow_scale'")

    def test_layer_manifest_valid(self):
        layer_dir = PROJECT_ROOT / "layer"
        manifest_files = list(layer_dir.glob("*.json"))
        self.assertGreater(len(manifest_files), 0, "At least one Vulkan layer manifest must exist")
        
        import json
        for mf in manifest_files:
            with open(mf, "r", encoding="utf-8") as f:
                data = json.load(f)
            self.assertIn("file_format_version", data)
            self.assertIn("layer", data)
            self.assertIn("name", data["layer"])
            self.assertIn("library_path", data["layer"])

    def test_compiled_layer_exists(self):
        layer_dir = PROJECT_ROOT / "layer"
        so_files = list(layer_dir.glob("*.so"))
        self.assertGreater(len(so_files), 0, "At least one compiled .so layer must be present in layer/")

if __name__ == "__main__":
    unittest.main()
