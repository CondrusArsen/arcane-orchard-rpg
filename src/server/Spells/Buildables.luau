--!strict
--[[
	Wall / Floor / Stairs placement.

	Every structure expires after `lifetime` seconds, each player can have at
	most `maxPerPlayer` alive at once (the oldest is removed first), and a
	player's structures are removed when they leave. Part count stays bounded
	no matter how long the server runs.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Spells = require(ReplicatedStorage.Shared.Config.Spells)
local Prefabs = require(script.Parent.Parent.Util.Prefabs)

local config = Spells.Buildables
local owned: { [Player]: { Model } } = {}

local Buildables = {}

local function forget(player: Player, model: Model)
	local list = owned[player]
	if not list then
		return
	end
	local index = table.find(list, model)
	if index then
		table.remove(list, index)
	end
end

local function remove(player: Player, model: Model)
	forget(player, model)
	model:Destroy()
end

function Buildables.canBuild(spellId: string): boolean
	return config.templates[spellId] ~= nil
end

-- `facing` orients the structure the way the caster is looking (yaw only).
function Buildables.place(player: Player, spellId: string, position: Vector3, facing: Vector3)
	local template = config.templates[spellId]
	if not template then
		return
	end
	local model = Prefabs.cloneModel("Magic", template.model)
	if not model then
		return
	end

	local flat = Vector3.new(facing.X, 0, facing.Z)
	local cframe = if flat.Magnitude > 1e-3 then CFrame.lookAt(position, position + flat) else CFrame.new(position)
	model:PivotTo(cframe)

	-- Ghost briefly so the structure cannot be used to shove players into walls.
	local mainPart = model:FindFirstChild(template.part, true)
	if mainPart and mainPart:IsA("BasePart") then
		mainPart.Transparency = 0.5
		mainPart.CanCollide = false
		task.delay(config.materializeSeconds, function()
			if mainPart.Parent then
				mainPart.Transparency = 0
				mainPart.CanCollide = true
			end
		end)
	end

	model.Parent = Prefabs.workspaceFolder(Prefabs.Folders.Buildables)

	local list = owned[player]
	if not list then
		list = {}
		owned[player] = list
	end
	table.insert(list, model)
	while #list > config.maxPerPlayer do
		remove(player, list[1])
	end

	task.delay(config.lifetime, function()
		if model.Parent then
			remove(player, model)
		end
	end)
end

function Buildables.start()
	Players.PlayerRemoving:Connect(function(player)
		local list = owned[player]
		owned[player] = nil
		if list then
			for _, model in list do
				model:Destroy()
			end
		end
	end)
end

return Buildables
