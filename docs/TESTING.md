# Testing Guide

## Studio Setup

1. Open `places/ArcaneOrchardRPG.rbxlx` in Roblox Studio.
2. Start with `Play` or `Play Here`.
3. Keep the Output window open.

## Smoke Test Checklist

- Player spawns without Output errors.
- Money, mana, and HP UI are visible.
- Shop opens and closes with the market button.
- Buying an ability removes money and reveals the skill icon.
- Fireball works with `Q`.
- Ice Arrow works with `E`.
- Spikes work with `X`.
- Wall, floor, and stairs work with `C`, `R`, and `F`.
- Super Magic unlocks from the shop and works with `T`.
- Super Magic creates visible explosions.
- Apples can be bought, eaten, and sold.
- Speed and jump boosters trigger on contact.
- NPCs spawn, patrol, detect players, attack, die, reward money, and respawn.

## Expected Studio Behavior

- DataStore calls are skipped in Studio.
- Published servers can use the DataStore path.
- Some Roblox asset warnings may appear if Studio cannot access external assets, but the main gameplay should continue.

## Suggested Manual Media Capture

- Screenshot: shop with Super Magic visible.
- Screenshot: player skill UI after buying abilities.
- Screenshot: world/orchard area.
- Screenshot or GIF: NPC combat.
- GIF/video: Super Magic meteor burst and explosions.

