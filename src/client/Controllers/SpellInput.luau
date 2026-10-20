--!strict
--[[
	Keyboard casting and the skill hotbar.

	The client only checks what it can show (unlocked, mana, cooldown) to give
	instant feedback; the server repeats every check before anything happens.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Attributes = require(ReplicatedStorage.Shared.Attributes)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Spells = require(ReplicatedStorage.Shared.Config.Spells)

local AIM_DISTANCE = 1000
local READY_STROKE = Color3.fromRGB(0, 85, 255)
local COOLDOWN_STROKE = Color3.new(0, 0, 0)

local player = Players.LocalPlayer
local coolingDown: { [string]: boolean } = {}
local hotbar: { [string]: GuiObject } = {}

local SpellInput = {}

local function isUnlocked(spellId: string): boolean
	return player:GetAttribute(Attributes.unlocked(spellId)) == true
end

local function currentMana(): number
	local mana = player:GetAttribute(Attributes.Mana)
	return if typeof(mana) == "number" then mana else 0
end

-- World point under the mouse cursor, ignoring the local character.
local function aimPoint(): Vector3?
	local camera = workspace.CurrentCamera
	if not camera then
		return nil
	end
	local mouse = UserInputService:GetMouseLocation()
	local ray = camera:ViewportPointToRay(mouse.X, mouse.Y)

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = if player.Character then { player.Character } else {}

	local result = workspace:Raycast(ray.Origin, ray.Direction * AIM_DISTANCE, params)
	return if result then result.Position else nil
end

local function showCooldown(spell: Spells.SpellDef)
	coolingDown[spell.id] = true

	local label = hotbar[spell.id]
	local overlay = label and label:FindFirstChild("CD")
	local stroke = label and label:FindFirstChildOfClass("UIStroke")
	if overlay and overlay:IsA("GuiObject") then
		overlay.BackgroundTransparency = 0.2
		TweenService:Create(overlay, TweenInfo.new(spell.cooldown, Enum.EasingStyle.Linear), {
			BackgroundTransparency = 1,
		}):Play()
	end
	if stroke then
		stroke.Color = COOLDOWN_STROKE
	end

	task.delay(spell.cooldown, function()
		coolingDown[spell.id] = nil
		if stroke then
			stroke.Color = READY_STROKE
		end
	end)
end

local function cast(spell: Spells.SpellDef)
	if coolingDown[spell.id] or not isUnlocked(spell.id) or currentMana() < spell.manaCost then
		return
	end

	if spell.targeted then
		local target = aimPoint()
		if not target then
			return
		end
		Remotes.CastSpell:FireServer(spell.id, target)
	else
		Remotes.CastSpell:FireServer(spell.id)
	end
	showCooldown(spell)
end

local function bindHotbarLabel(spell: Spells.SpellDef, skillGui: Instance)
	local label = skillGui:FindFirstChild(spell.hotbarLabel, true)
	if not (label and label:IsA("GuiObject")) then
		warn(`[SpellInput] Hotbar label "{spell.hotbarLabel}" not found`)
		return
	end
	hotbar[spell.id] = label

	local function refresh()
		label.Visible = isUnlocked(spell.id)
	end
	refresh()
	player:GetAttributeChangedSignal(Attributes.unlocked(spell.id)):Connect(refresh)
end

function SpellInput.start()
	local skillGui = player:WaitForChild("PlayerGui"):WaitForChild("SkillGui")

	local byKey: { [Enum.KeyCode]: Spells.SpellDef } = {}
	for _, spell in Spells.definitions do
		byKey[spell.key] = spell
		bindHotbarLabel(spell, skillGui)
	end

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end
		local spell = byKey[input.KeyCode]
		if spell then
			cast(spell)
		end
	end)
end

return SpellInput
