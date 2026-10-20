# Testing

## Automated (CI)

| Check | What it covers |
| --- | --- |
| StyLua | Formatting of `src`, `tools`, `tests` |
| Selene (Roblox std) | Lint: unused code, shadowing, wrong API use |
| Rojo build | The project file maps every module correctly |
| luau-lsp analyze | `--!strict` type checking against the Rojo sourcemap |
| `tests/Economy.spec.luau` | Prices, generator intervals and catalogue rules |

## Manual playtest in Studio

Setup: `rojo serve`, open the place, connect the Rojo plugin, run `tools/clean-place.luau` once, then **Play** (or **Start** with 2 players for multiplayer checks). Keep the Output window open; there should be no errors.

### Core loop

- [ ] HUD shows 100/100 HP, 100/100 mana and 500$.
- [ ] Shop opens and closes with **Open Market**; prices and mana costs match `src/shared/Config`.
- [ ] Buying the money generator takes 100$; the generator panel shows level 1 and coins grow while mana drains.
- [ ] Buying with too little money shows a message and changes nothing.
- [ ] Buying a spell shows it in the hotbar and the button changes to **Owned**.
- [ ] Each spell works on its key; cooldown overlay matches the config cooldown.
- [ ] Fireball and Super Magic damage enemies; Ice Arrow damages and freezes; Spikes damage enemies standing on them.
- [ ] Walls, floors and stairs face the player, become solid after ~1 s and disappear after 45 s; a 7th structure removes the oldest one.
- [ ] Apples can be bought, eaten (heal) and sold at the price shown.
- [ ] Speed and jump pads boost the player and reset afterwards.
- [ ] Enemies patrol, attack when a player comes close, die, pay the killer and respawn after a few seconds.

### Server validation (run in the command bar while playing, client context)

```lua
local remotes = game.ReplicatedStorage.Remotes
remotes.CastSpell:FireServer("Super", Vector3.new(0, 0, 0))   -- not unlocked: nothing happens
remotes.CastSpell:FireServer("FireBall", "not a vector")       -- ignored
remotes.CastSpell:FireServer("Spikes", Vector3.new(1e9, 0, 0)) -- out of range: no mana spent
remotes.PurchaseItem:FireServer("FireBall")                    -- refused without enough coins
remotes.PurchaseItem:FireServer({})                            -- ignored
for _ = 1, 100 do remotes.SellApple:FireServer() end           -- rate limited, sells only owned apples
```

### Persistence (published place, API access enabled)

- [ ] Coins, unlocks and generator levels survive rejoining.
- [ ] Shutting down a server saves every player (BindToClose).
