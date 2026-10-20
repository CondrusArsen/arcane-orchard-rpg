--!strict
--[[
	Single source of truth for every castable spell.

	The server reads mana costs, cooldowns and ranges to validate casts.
	The client reads the same table for keybinds, cooldown overlays and
	shop labels, so the numbers players see always match the rules the
	server enforces.
]]

export type SpellId = "FireBall" | "IceArrow" | "Spikes" | "Wall" | "Floor" | "Stairs" | "Super"

export type SpellDef = {
	id: SpellId,
	displayName: string,
	manaCost: number,
	cooldown: number,
	-- Targeted spells send a world position that the server re-validates against `range`.
	targeted: boolean,
	range: number,
	key: Enum.KeyCode,
	-- ImageLabel inside StarterGui.SkillGui that represents the spell in the hotbar.
	hotbarLabel: string,
}

local definitions: { [string]: SpellDef } = {
	FireBall = {
		id = "FireBall",
		displayName = "Fireball",
		manaCost = 40,
		cooldown = 2,
		targeted = false,
		range = 0,
		key = Enum.KeyCode.Q,
		hotbarLabel = "FireBallLabel",
	},
	IceArrow = {
		id = "IceArrow",
		displayName = "Ice Arrow",
		manaCost = 35,
		cooldown = 1.75,
		targeted = false,
		range = 0,
		key = Enum.KeyCode.E,
		hotbarLabel = "ArrowLabel",
	},
	Spikes = {
		id = "Spikes",
		displayName = "Spikes",
		manaCost = 15,
		cooldown = 1.5,
		targeted = true,
		range = 40,
		key = Enum.KeyCode.X,
		hotbarLabel = "SpikesLabel",
	},
	Wall = {
		id = "Wall",
		displayName = "Wall",
		manaCost = 7,
		cooldown = 0.75,
		targeted = true,
		range = 40,
		key = Enum.KeyCode.C,
		hotbarLabel = "WallLabel",
	},
	Floor = {
		id = "Floor",
		displayName = "Floor",
		manaCost = 10,
		cooldown = 0.75,
		targeted = true,
		range = 40,
		key = Enum.KeyCode.R,
		hotbarLabel = "FloorLabel",
	},
	Stairs = {
		id = "Stairs",
		displayName = "Stairs",
		manaCost = 12,
		cooldown = 0.75,
		targeted = true,
		range = 40,
		key = Enum.KeyCode.F,
		hotbarLabel = "StairsLabel",
	},
	Super = {
		id = "Super",
		displayName = "Super Magic",
		manaCost = 100,
		cooldown = 10,
		targeted = true,
		range = 150,
		key = Enum.KeyCode.T,
		hotbarLabel = "SuperiorLabel",
	},
}

local Spells = {
	definitions = definitions,

	-- The game is co-op PvE: player spells hurt NPCs, NPC spells hurt players.
	playerVersusPlayer = false,

	-- Effect tuning lives next to the costs so balancing happens in one file.
	FireBall = {
		speed = 70,
		damage = 35,
		lifetime = 4,
		blastRadius = 12,
		-- Initial upward speed and gravity give the fireball a short arc.
		launchLift = 45,
		gravity = 30,
	},
	IceArrow = {
		speed = 85,
		damage = 20,
		lifetime = 4,
		freezeSeconds = 1.75,
	},
	Spikes = {
		damage = 30,
		lifetime = 6,
		hitCooldown = 1.5,
	},
	Super = {
		meteorCount = 28,
		damage = 35,
		blastRadius = 11,
		spread = 33,
		dropHeight = 75,
		fallSeconds = 0.9,
		burstSeconds = 1.4,
	},
	Buildables = {
		-- Built structures expire so a long session cannot fill the server with parts.
		lifetime = 45,
		maxPerPlayer = 6,
		materializeSeconds = 1.25,
		templates = {
			Wall = { model = "wall", part = "Building_wall" },
			Floor = { model = "floor", part = "Building_floor" },
			Stairs = { model = "stairs", part = "Building_stairs" },
		} :: { [string]: { model: string, part: string } },
	},
}

function Spells.get(id: unknown): SpellDef?
	if typeof(id) ~= "string" then
		return nil
	end
	return definitions[id]
end

return Spells
