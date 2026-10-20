--!strict
--[[
	Handles CastSpell requests from clients.

	Order of checks: rate limit -> known spell -> unlocked -> alive ->
	cooldown -> target valid and in range -> mana. Mana is spent only after
	every other check passed, so a rejected or missed cast is free.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Spells = require(ReplicatedStorage.Shared.Config.Spells)
local Buildables = require(script.Parent.Parent.Spells.Buildables)
local PlayerData = require(script.Parent.PlayerData)
local RateLimiter = require(script.Parent.Parent.Util.RateLimiter)
local SpellEffects = require(script.Parent.Parent.Spells.SpellEffects)
local Validate = require(script.Parent.Parent.Util.Validate)

-- Allow a little network jitter on cooldowns and on the distance check.
local COOLDOWN_TOLERANCE = 0.9
local RANGE_TOLERANCE = 6
local CAST_OFFSET = CFrame.new(0, 0, -5)

local allowCast = RateLimiter.new(8, 8)
local lastCast: { [Player]: { [string]: number } } = {}

local SpellService = {}

local function cooldownReady(player: Player, spell: Spells.SpellDef, now: number): boolean
	local history = lastCast[player]
	local previous = history and history[spell.id]
	return previous == nil or now - previous >= spell.cooldown * COOLDOWN_TOLERANCE
end

local function recordCast(player: Player, spellId: string, now: number)
	local history = lastCast[player]
	if not history then
		history = {}
		lastCast[player] = history
	end
	history[spellId] = now
end

-- Turns the requested point into the point the spell will actually use.
local function resolveTarget(spell: Spells.SpellDef, root: BasePart, rawTarget: unknown): Vector3?
	local requested = Validate.vector3(rawTarget)
	if not requested then
		return nil
	end
	if (requested - root.Position).Magnitude > spell.range + RANGE_TOLERANCE then
		return nil
	end
	if spell.id == "Super" then
		return requested
	end
	-- Spikes and structures snap to the ground; no ground means nothing to cast on.
	return SpellEffects.groundBelow(requested)
end

local function onCastSpell(player: Player, spellId: unknown, rawTarget: unknown)
	if not allowCast(player) then
		return
	end

	local spell = Spells.get(spellId)
	if not spell or not PlayerData.isUnlocked(player, spell.id) then
		return
	end

	local character, root = Validate.aliveRoot(player)
	if not character or not root then
		return
	end

	local now = os.clock()
	if not cooldownReady(player, spell, now) then
		return
	end

	local target: Vector3? = nil
	if spell.targeted then
		target = resolveTarget(spell, root, rawTarget)
		if not target then
			return
		end
	end

	if not PlayerData.trySpendMana(player, spell.manaCost) then
		return
	end
	recordCast(player, spell.id, now)

	local attacker = { model = character, player = player }
	if spell.id == "FireBall" then
		SpellEffects.fireball(attacker, root.CFrame * CAST_OFFSET)
	elseif spell.id == "IceArrow" then
		SpellEffects.iceArrow(attacker, root.CFrame * CAST_OFFSET)
	elseif target and spell.id == "Spikes" then
		SpellEffects.spikes(attacker, target)
	elseif target and spell.id == "Super" then
		SpellEffects.super(attacker, target)
	elseif target and Buildables.canBuild(spell.id) then
		Buildables.place(player, spell.id, target, root.CFrame.LookVector)
	end
end

function SpellService.start()
	Remotes.CastSpell.OnServerEvent:Connect(onCastSpell)
	Players.PlayerRemoving:Connect(function(player)
		lastCast[player] = nil
	end)
end

return SpellService
