--!strict
--[[
	Enemy archetypes. One behaviour module (server/Npc/NpcBrain) drives every
	enemy; the differences between an archer and a magician are data.
]]

export type NpcSpell = "FireBall" | "IceArrow" | "Spikes"

export type Attack = {
	spell: NpcSpell,
	minRange: number,
	maxRange: number,
	-- Seconds before this NPC may attack again after using this attack.
	recovery: number,
}

export type Archetype = {
	detectRadius: number,
	walkSpeed: number,
	reward: number,
	-- Ordered by priority; the first attack whose range contains the target is used.
	attacks: { Attack },
}

local archetypes: { [string]: Archetype } = {
	Archer = {
		detectRadius = 100,
		walkSpeed = 16,
		reward = 25,
		attacks = {
			{ spell = "IceArrow", minRange = 0, maxRange = 100, recovery = 3.25 },
		},
	},
	Magicion = {
		detectRadius = 210,
		walkSpeed = 16,
		reward = 35,
		attacks = {
			{ spell = "Spikes", minRange = 0, maxRange = 40, recovery = 3 },
			{ spell = "IceArrow", minRange = 40, maxRange = 190, recovery = 4 },
			{ spell = "FireBall", minRange = 190, maxRange = 210, recovery = 6 },
		},
	},
}

return {
	archetypes = archetypes,

	walkAnimationId = "rbxassetid://180426354",
	-- How often an engaged NPC re-evaluates its target and turns to face it.
	thinkInterval = 0.1,
	patrolPause = 1,
	-- Give up on a waypoint if the humanoid has not reached it in this time.
	waypointTimeout = 3,
	respawnDelay = 5,
	corpseLifetime = 2,

	pathAgent = {
		AgentRadius = 2.5,
		AgentHeight = 6.5,
		AgentCanJump = true,
	},
}
