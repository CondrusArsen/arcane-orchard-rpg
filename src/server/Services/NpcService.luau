--!strict
--[[
	Spawns enemies from ReplicatedStorage.Rigs onto free spawn points,
	pays the killer, and respawns a random enemy after a delay.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NpcConfig = require(ReplicatedStorage.Shared.Config.Npc)
local NpcBrain = require(script.Parent.Parent.Npc.NpcBrain)
local PlayerData = require(script.Parent.PlayerData)
local Prefabs = require(script.Parent.Parent.Util.Prefabs)

local occupied: { [BasePart]: boolean } = {}
local spawnPoints: { BasePart } = {}
-- Template names, one entry per template in ReplicatedStorage.Rigs (duplicates act as weights).
local roster: { string } = {}
local patrolFolder: Instance? = nil
local random = Random.new()

local NpcService = {}

local function freeSpawnPoint(): BasePart?
	local free = {}
	for _, point in spawnPoints do
		if not occupied[point] then
			table.insert(free, point)
		end
	end
	if #free == 0 then
		return nil
	end
	return free[random:NextInteger(1, #free)]
end

local function patrolRoute(spawnPoint: BasePart): { BasePart }
	local route = { spawnPoint }
	local partner = patrolFolder and patrolFolder:FindFirstChild(spawnPoint.Name)
	if partner and partner:IsA("BasePart") then
		table.insert(route, partner)
	end
	return route
end

local spawnRandom: () -> ()

local function onDied(rig: Model, humanoid: Humanoid, spawnPoint: BasePart, archetype: NpcConfig.Archetype)
	local tag = humanoid:FindFirstChild("creator")
	local killer = if tag and tag:IsA("ObjectValue") then tag.Value else nil
	if killer and killer:IsA("Player") then
		PlayerData.addMoney(killer, archetype.reward)
	end

	local deathSound = rig:FindFirstChild("Sound")
	if deathSound and deathSound:IsA("Sound") then
		deathSound:Play()
	end

	occupied[spawnPoint] = nil
	task.delay(NpcConfig.corpseLifetime, function()
		rig:Destroy()
	end)
	task.delay(NpcConfig.respawnDelay, spawnRandom)
end

local function spawnEnemy(templateName: string)
	local archetype = NpcConfig.archetypes[templateName]
	local spawnPoint = freeSpawnPoint()
	if not archetype or not spawnPoint then
		return
	end

	local rig = Prefabs.cloneModel("Rigs", templateName)
	local humanoid = rig and rig:FindFirstChildOfClass("Humanoid")
	if not rig or not humanoid then
		return
	end

	occupied[spawnPoint] = true
	rig:SetAttribute("IsNpc", true)
	rig:PivotTo(spawnPoint.CFrame)
	rig.Parent = Prefabs.workspaceFolder(Prefabs.Folders.Enemies)

	-- The server simulates enemies so clients cannot move them.
	local root = rig:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		pcall(function()
			root:SetNetworkOwner(nil)
		end)
	end

	humanoid.Died:Once(function()
		onDied(rig, humanoid, spawnPoint, archetype)
	end)
	NpcBrain.run(rig, archetype, patrolRoute(spawnPoint))
end

spawnRandom = function()
	if #roster > 0 then
		spawnEnemy(roster[random:NextInteger(1, #roster)])
	end
end

function NpcService.start()
	local world = workspace:WaitForChild("World")
	local spawnFolder = world:WaitForChild("SpawnPartsFolder")
	patrolFolder = world:WaitForChild("MovePartsFolder")

	for _, child in spawnFolder:GetChildren() do
		if child:IsA("BasePart") then
			table.insert(spawnPoints, child)
		end
	end

	for _, template in ReplicatedStorage:WaitForChild("Rigs"):GetChildren() do
		if template:IsA("Model") then
			if NpcConfig.archetypes[template.Name] then
				table.insert(roster, template.Name)
			else
				warn(`[NpcService] No archetype configured for rig "{template.Name}"`)
			end
		end
	end

	for _, templateName in roster do
		spawnEnemy(templateName)
	end
end

return NpcService
