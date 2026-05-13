# Extracted Scripts

This folder contains Luau scripts extracted from `places/ArcaneOrchardRPG.rbxlx` for review in GitHub.

The canonical playable project is still the Roblox place file:

```text
places/ArcaneOrchardRPG.rbxlx
```

The scripts are exported with their original Roblox hierarchy encoded in the filename. Use `scripts_manifest.json` to map each file back to its Roblox path.

Examples:

- `ServerScriptService/MyFolder/Magic` contains spell spawning and server-side validation.
- `ServerScriptService/MyFolder/DataStore` contains player money/mana persistence.
- `StarterPlayer/StarterPlayerScripts/Input` contains ability keybind handling.
- `StarterGui/ShopGui/Shopping` contains shop unlock and upgrade flow.
- `Workspace/World/Boosters/...` contains shared booster controller scripts.

This is not a full Rojo source tree yet. It is a GitHub-readable export of the scripts inside the place file.

