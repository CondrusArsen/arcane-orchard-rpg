--!strict
--[[
	Speed and jump pads. One controller handles every pad in the configured
	folders (previously each pad carried its own copy of the script).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Boosters = require(ReplicatedStorage.Shared.Config.Boosters)

-- Humanoids currently boosted, per booster property.
local boosted: { [string]: { [Humanoid]: boolean } } = {}

local BoosterService = {}

local function readProperty(humanoid: Humanoid, property: "WalkSpeed" | "JumpHeight"): number
	return if property == "WalkSpeed" then humanoid.WalkSpeed else humanoid.JumpHeight
end

local function writeProperty(humanoid: Humanoid, property: "WalkSpeed" | "JumpHeight", value: number)
	if property == "WalkSpeed" then
		humanoid.WalkSpeed = value
	else
		humanoid.JumpHeight = value
	end
end

local function apply(booster: Boosters.Booster, humanoid: Humanoid)
	local active = boosted[booster.property]
	if active[humanoid] then
		return
	end
	active[humanoid] = true

	local original = readProperty(humanoid, booster.property)
	writeProperty(humanoid, booster.property, booster.value)

	task.delay(booster.duration, function()
		active[humanoid] = nil
		if humanoid.Parent then
			writeProperty(humanoid, booster.property, original)
		end
	end)
end

local function hookPad(booster: Boosters.Booster, pad: Instance)
	if not pad:IsA("BasePart") then
		return
	end
	pad.Touched:Connect(function(hit)
		local character = hit.Parent
		if not character or not Players:GetPlayerFromCharacter(character) then
			return
		end
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.Health > 0 then
			apply(booster, humanoid)
		end
	end)
end

function BoosterService.start()
	local world = workspace:WaitForChild("World")
	local root = world:FindFirstChild("Boosters")
	if not root then
		warn("[BoosterService] Workspace.World.Boosters not found")
		return
	end

	for _, booster in Boosters do
		boosted[booster.property] = {}
		local folder = root:FindFirstChild(booster.folder)
		if folder then
			for _, pad in folder:GetDescendants() do
				hookPad(booster, pad)
			end
			folder.DescendantAdded:Connect(function(pad)
				hookPad(booster, pad)
			end)
		else
			warn(`[BoosterService] Booster folder "{booster.folder}" not found`)
		end
	end
end

return BoosterService
