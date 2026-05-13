# RPG_clean.rbxlx changelog

## First stabilization pass

- Created a safe working copy at `C:\Users\arsen\Documents\Codex\2026-05-11\roblox-github\RPG_clean.rbxlx`.
- Replaced 9 high-risk scripts:
  - `ServerScriptService/MyFolder/Magic`
  - `ServerScriptService/MyFolder/DataStore`
  - `ServerScriptService/MoneyGenScript`
  - `ServerScriptService/NPCspawnScript`
  - `ReplicatedStorage/Magic/FireBall_Prefab/FireBallBehaviour`
  - `ReplicatedStorage/Magic/IceArrowPrefab/IceArrowBehaviour`
  - `ReplicatedStorage/Magic/Spikes_Prefab/SpikesBehaviour`
  - `StarterGui/ShopGui/Shopping`
  - `StarterGui/ShopGui/ShopFrame/ApplesFrame/Cost/AppleSellScript`
- Capped the super attack from an unsafe `100000000` loop to a bounded projectile burst.
- Stopped the money generator from accepting a client-provided money total.
- Added basic server validation/rate limiting for money and mana generator events.
- Changed apple buying so the server checks and subtracts money before giving the tool.
- Made fireball explosions stop destroying map parts directly.
- Added safer projectile cleanup through `Debris`.
- Fixed NPC spawn event logic so it clones templates instead of moving the template out of `ReplicatedStorage`.
- Replaced 44 duplicated booster scripts with 2 folder-level controller scripts:
  - `Workspace/World/Boosters/Jump_Boosters/JumpBoostersController`
  - `Workspace/World/Boosters/SpeedBoosters/SpeedBoostersController`

## Second stabilization and polish pass

- Added basic Roblox `DataStoreService` persistence for player money and mana.
  - Loads saved values on join.
  - Autosaves during play.
  - Saves on leave and server close.
  - Falls back to prototype defaults if Studio/API access blocks DataStore calls.
- Added a runtime UI polish controller in `StarterGui/ManaGui/ManaGenFrame/LocalScript`.
  - Applies consistent fonts, wrapped/scaled text, corners, strokes, button styling, and responsive `UIScale`.
  - Repositions/sizes the shop panel and open button more safely for different screens.
- Reworked `StarterPlayer/StarterPlayerScripts/Input`.
  - Ignores processed input.
  - Uses one spell table for keybinds, costs, cooldowns, and labels.
  - Keeps client cooldown visual while the server still owns mana spending.
- Reworked `StarterPlayer/StarterPlayerScripts/Value`.
  - Clamps HP/mana bar values to `0..100`.
  - Avoids UI bars growing outside their containers.
- Hardened apple `ServerSideHandler` scripts.
  - Server only accepts bite/finish events while the apple tool is actually equipped.
  - Each apple can heal only once.
  - Healing uses `Humanoid.Health` clamp instead of negative damage.
- Reworked NPC reward scripts.
  - Rewards only once per NPC death.
  - Checks that the tagged player and money value still exist.
  - Releases occupied spawn parts safely.
- Preserved the original IceArrow prefab movement axis while keeping raycast cleanup/damage logic.

## Static UI properties pass

- Moved the UI visual styling out of runtime code and into saved `StarterGui` properties.
- Styled 112 saved GUI objects directly in `RPG_clean.rbxlx`.
- Added/updated saved UI helper instances:
  - `69` `UICorner`
  - `49` `UIStroke`
  - `5` `UIScale`
- Applied static properties for:
  - panel/button/text colors
  - `TextScaled`
  - `TextWrapped`
  - SourceSansPro font faces
  - shop panel anchor, position, and size
  - open market button anchor, position, and size
  - value/mana/HP bar styling
- Cleared the runtime UI-polish script body at `StarterGui/ManaGui/ManaGenFrame/LocalScript`.
  - The script now only contains a comment.
  - UI appearance should be visible in Studio edit mode before pressing Play.

## Studio Output Fixes

- Replaced inaccessible Magicion animation asset `85972648923109`.
  - New fallback animation: `rbxassetid://180426354`.
  - This should remove the "experience doesn't have access permission" warning for that asset.
- Added a Studio guard around DataStore access.
  - In Studio, `DataStore` load/save calls are skipped.
  - In a published game/server, the same script still uses `DataStoreService`.
  - This should remove `StudioAccessToApisNotAllowed` during local Studio testing.

## Super Magic Shop Fix

- Fixed the shop purchase path for `SuperiorFrame`.
  - The cleaned `Shopping` script now unlocks `SkillGui/SuperFrame/SuperiorLabel` when category is `SuperFrame`.
  - This no longer depends on a missing `Name` value.
- Added a saved `StringValue` named `Name` with value `SuperiorLabel` under `ShopGui/ShopFrame/SuperiorFrame` for consistency.
- Updated the saved shop text to `Super Magic (T) cost 1000$`.
- Made `SuperiorFrame` visually distinct with a purple panel/button style.

## Super Magic Explosion Fix

- Restored `Explosion` creation inside the bounded Super Magic implementation.
- Kept the safe projectile cap through `SUPER_PROJECTILE_COUNT = 28`.
- Explosion settings:
  - `BlastRadius = SUPER_RADIUS`
  - `BlastPressure = 100`
  - `DestroyJointRadiusPercent = 0`
- Explosion hits now tag the caster and apply `SUPER_DAMAGE`, while skipping self-damage.

## Verification

- `RPG_clean.rbxlx` parses successfully as XML after edits.
- Script count changed from 103 to 61.
- Total instance count changed from 22,085 to 22,091 after static UI helper objects were added.
- `StarterGui` now contains saved static UI styling objects, including `UIScale`, `UICorner`, and `UIStroke`.
- No remaining active matches for:
  - `100000000`
  - direct `money.Value = money` assignment from client payload
  - placeholder owner string `kakie nibud`
  - projectile `v:Destroy()` map destruction
  - apple healing through `TakeDamage(-...)`

## Still Needs Studio Testing

- Open `RPG_clean.rbxlx` in Roblox Studio.
- Run Play Solo and check:
  - UI opens and buttons fit.
  - Buying skills/buildings unlocks the expected labels.
  - Apple buy/sell works and money updates.
  - Money/mana generators work without runaway growth.
  - Fireball, ice arrow, spikes, building spells, and super attack spawn correctly.
  - NPCs spawn, patrol, detect players, and attack.
  - Jump/speed boosters still trigger on every booster part.
