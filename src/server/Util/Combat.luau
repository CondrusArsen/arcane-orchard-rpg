--!strict
--[[
	Damage rules shared by player spells and NPC attacks.

	Every hit goes through `Combat.damage`, which checks who may hurt whom and
	writes the standard `creator` tag so kill rewards can be attributed.
]]

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Spells = require(ReplicatedStorage.Shared.Config.Spells)

export type Attacker = {
	model: Model,
	-- Set when a player cast the spell; used for kill rewards.
	player: Player?,
}

local CREATOR_TAG_SECONDS = 4

local Combat = {}

function Combat.isNpc(model: Instance): boolean
	return model:GetAttribute("IsNpc") == true
end

-- Finds the character model and humanoid a part belongs to, if any.
function Combat.humanoidOf(part: Instance): (Model?, Humanoid?)
	local model = part:FindFirstAncestorOfClass("Model")
	if not model then
		return nil, nil
	end
	return model, model:FindFirstChildOfClass("Humanoid")
end

function Combat.canDamage(attacker: Attacker, victim: Model): boolean
	if victim == attacker.model then
		return false
	end

	local victimIsNpc = Combat.isNpc(victim)
	local victimIsPlayer = Players:GetPlayerFromCharacter(victim) ~= nil
	if not victimIsNpc and not victimIsPlayer then
		-- Decorative humanoids (quest givers, props) are not combat targets.
		return false
	end

	if Combat.isNpc(attacker.model) then
		return victimIsPlayer
	end
	return victimIsNpc or Spells.playerVersusPlayer
end

function Combat.damage(attacker: Attacker, victim: Model, humanoid: Humanoid, amount: number): boolean
	if humanoid.Health <= 0 or not Combat.canDamage(attacker, victim) then
		return false
	end

	local player = attacker.player
	if player then
		-- Replace rather than reuse the tag so an older Debris timer cannot remove the new one.
		local existing = humanoid:FindFirstChild("creator")
		if existing then
			existing:Destroy()
		end
		local creator = Instance.new("ObjectValue")
		creator.Name = "creator"
		creator.Value = player
		creator.Parent = humanoid
		Debris:AddItem(creator, CREATOR_TAG_SECONDS)
	end

	humanoid:TakeDamage(amount)
	return true
end

-- Damages every valid humanoid with a part inside the sphere, once each.
function Combat.damageInRadius(attacker: Attacker, position: Vector3, radius: number, amount: number)
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { attacker.model }

	local hit: { [Humanoid]: boolean } = {}
	for _, part in workspace:GetPartBoundsInRadius(position, radius, params) do
		local model, humanoid = Combat.humanoidOf(part)
		if model and humanoid and not hit[humanoid] then
			hit[humanoid] = true
			Combat.damage(attacker, model, humanoid, amount)
		end
	end
end

return Combat
