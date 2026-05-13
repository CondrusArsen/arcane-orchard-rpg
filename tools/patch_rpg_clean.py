from __future__ import annotations

import xml.etree.ElementTree as ET
from pathlib import Path


ROOT = Path(r"C:\Users\arsen\Documents\Codex\2026-05-11\roblox-github")
PLACE = ROOT / "RPG_clean.rbxlx"


SOURCES_BY_PATH = {
    "ServerScriptService/MyFolder/DataStore": r'''local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local events = ReplicatedStorage:WaitForChild("Events")
local manaEvent = events:WaitForChild("MANAevent")
local buyEvent = events:WaitForChild("BuyEvent")
local USE_DATASTORE = not RunService:IsStudio()
local playerStore = USE_DATASTORE and DataStoreService:GetDataStore("RPGPrototype_Player_v1") or nil

local STARTING_MANA = 100
local MAX_MANA = 100
local STARTING_MONEY = 500
local MAX_PURCHASE_COST = 1000000
local AUTOSAVE_INTERVAL = 60

local sessionData = {}

local function getOrCreateInt(parent, name, value)
	local item = parent:FindFirstChild(name)
	if not item then
		item = Instance.new("IntValue")
		item.Name = name
		item.Parent = parent
	end
	item.Value = value
	return item
end

local function sendValues(player)
	local mana = player:FindFirstChild("Mana")
	local money = player:FindFirstChild("money")
	if mana and money then
		manaEvent:FireClient(player, mana.Value, money.Value)
	end
end

local function loadData(player)
	if not USE_DATASTORE then
		return {
			Mana = STARTING_MANA,
			Money = STARTING_MONEY,
		}
	end

	local ok, data = pcall(function()
		return playerStore:GetAsync(tostring(player.UserId))
	end)

	if ok and typeof(data) == "table" then
		return {
			Mana = math.clamp(tonumber(data.Mana) or STARTING_MANA, 0, MAX_MANA),
			Money = math.max(0, math.floor(tonumber(data.Money) or STARTING_MONEY)),
		}
	end

	return {
		Mana = STARTING_MANA,
		Money = STARTING_MONEY,
	}
end

local function saveData(player)
	local mana = player:FindFirstChild("Mana")
	local money = player:FindFirstChild("money")
	if not mana or not money then
		return
	end

	sessionData[player] = {
		Mana = mana.Value,
		Money = money.Value,
	}

	if not USE_DATASTORE then
		return
	end

	pcall(function()
		playerStore:SetAsync(tostring(player.UserId), sessionData[player])
	end)
end

Players.PlayerAdded:Connect(function(player)
	local loaded = loadData(player)
	local mana = getOrCreateInt(player, "Mana", loaded.Mana)
	local money = getOrCreateInt(player, "money", loaded.Money)
	sessionData[player] = loaded

	player.CharacterAdded:Connect(function()
		local npcSpawner = game.ServerScriptService:FindFirstChild("NPCspawnScript")
		if npcSpawner then
			npcSpawner.Enabled = true
		end
	end)

	task.spawn(function()
		local lastSave = os.clock()
		while player.Parent == Players do
			if mana.Value < MAX_MANA then
				mana.Value = math.min(MAX_MANA, mana.Value + 1)
			end
			sendValues(player)
			if os.clock() - lastSave >= AUTOSAVE_INTERVAL then
				lastSave = os.clock()
				saveData(player)
			end
			task.wait(0.35)
		end
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	saveData(player)
	sessionData[player] = nil
end)

game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		saveData(player)
	end
end)

buyEvent.OnServerEvent:Connect(function(player, cost)
	cost = tonumber(cost)
	if not cost then
		return
	end

	cost = math.floor(cost)
	if cost < 0 or cost > MAX_PURCHASE_COST then
		return
	end

	local money = player:FindFirstChild("money")
	if not money or money.Value < cost then
		return
	end

	money.Value -= cost
	sendValues(player)
	saveData(player)
end)
''',
    "ServerScriptService/MoneyGenScript": r'''local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local events = ReplicatedStorage:WaitForChild("Events")
local moneyGenEvent = events:WaitForChild("MoneyGenEvent")
local manaGenEvent = events:WaitForChild("ManaGenEvent")

local MAX_MANA = 100
local MIN_INTERVAL = 0.25
local lastMoneyTick = {}
local lastManaTick = {}

local function ready(cache, player)
	local now = os.clock()
	if cache[player] and now - cache[player] < MIN_INTERVAL then
		return false
	end
	cache[player] = now
	return true
end

moneyGenEvent.OnServerEvent:Connect(function(player)
	if not ready(lastMoneyTick, player) then
		return
	end

	local mana = player:FindFirstChild("Mana")
	local money = player:FindFirstChild("money")
	if not mana or not money or mana.Value < 1 then
		return
	end

	mana.Value -= 1
	money.Value += 1
end)

manaGenEvent.OnServerEvent:Connect(function(player)
	if not ready(lastManaTick, player) then
		return
	end

	local mana = player:FindFirstChild("Mana")
	if mana and mana.Value < MAX_MANA then
		mana.Value = math.min(MAX_MANA, mana.Value + 1)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	lastMoneyTick[player] = nil
	lastManaTick[player] = nil
end)
''',
    "ServerScriptService/MyFolder/Magic": r'''local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local events = ReplicatedStorage:WaitForChild("Events")
local magic = ReplicatedStorage:WaitForChild("Magic")

local fireballEvent = events:WaitForChild("FireBallEvent")
local spikesEvent = events:WaitForChild("SpikesEvent")
local wallEvent = events:WaitForChild("WallEvent")
local floorEvent = events:WaitForChild("FloorEvent")
local stairsEvent = events:WaitForChild("StairsEvent")
local iceArrowEvent = events:WaitForChild("IceArrowEvent")
local superEvent = events:WaitForChild("SuperEvent")

local npcArrowEvent = events:WaitForChild("NPC_arrow_Event")
local npcBallEvent = events:WaitForChild("NPC_ball_Event")
local npcSpikesEvent = events:WaitForChild("NPC_spikes_Event")

local MAX_BUILD_DISTANCE = 40
local MAX_SUPER_DISTANCE = 150
local SUPER_PROJECTILE_COUNT = 28
local SUPER_DAMAGE = 35
local SUPER_RADIUS = 11

local costs = {
	FireBall = 40,
	Spikes = 15,
	Wall = 7,
	Floor = 10,
	Stairs = 12,
	IceArrow = 35,
	Super = 100,
}
local cooldowns = {
	FireBall = 1.25,
	Spikes = 1.5,
	Wall = 0.75,
	Floor = 0.75,
	Stairs = 0.75,
	IceArrow = 1.75,
	Super = 10,
}

local lastCast = {}

local function getCharacterRoot(player)
	local character = player.Character
	if not character then
		return nil
	end
	return character, character:FindFirstChild("HumanoidRootPart")
end

local function canCast(player, spell)
	local mana = player:FindFirstChild("Mana")
	if not mana or mana.Value < costs[spell] then
		return false
	end

	local now = os.clock()
	lastCast[player] = lastCast[player] or {}
	if lastCast[player][spell] and now - lastCast[player][spell] < cooldowns[spell] then
		return false
	end

	lastCast[player][spell] = now
	mana.Value -= costs[spell]
	return true
end

local function rayToGround(player, position, maxDistance)
	if typeof(position) ~= "Vector3" then
		return nil
	end

	local _, root = getCharacterRoot(player)
	if not root or (position - root.Position).Magnitude > maxDistance then
		return nil
	end

	local ignoreList = {}
	for _, item in ipairs(workspace:GetDescendants()) do
		if item:IsA("Humanoid") and item.Parent then
			table.insert(ignoreList, item.Parent)
		end
	end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignoreList

	return workspace:Raycast(position + Vector3.new(0, 50, 0), Vector3.new(0, -200, 0), params)
end

local function setOwner(model, characterOrPlayer)
	local player = characterOrPlayer
	if typeof(characterOrPlayer) == "Instance" and not characterOrPlayer:IsA("Player") then
		player = game.Players:GetPlayerFromCharacter(characterOrPlayer)
	end

	if player then
		model:SetAttribute("OwnerId", player.UserId)
	end
end

local function spawnFireball(character)
	local _, root = character, character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end

	local clone = magic:WaitForChild("FireBall_Prefab"):Clone()
	clone.Parent = workspace
	setOwner(clone, character)
	clone:PivotTo(root.CFrame * CFrame.new(0, 0, -5))
	Debris:AddItem(clone, 8)
end

local function spawnIceArrow(character)
	local _, root = character, character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end

	local clone = magic:WaitForChild("IceArrowPrefab"):Clone()
	clone.Parent = workspace
	setOwner(clone, character)
	clone:PivotTo(root.CFrame * CFrame.new(0, 0, -5))
	Debris:AddItem(clone, 8)
end

local function spawnSpikes(owner, position)
	local clone = magic:WaitForChild("Spikes_Prefab"):Clone()
	clone.Parent = workspace
	setOwner(clone, owner)
	clone:PivotTo(CFrame.new(position + Vector3.new(0, 1, 0)))
	Debris:AddItem(clone, 7)
end

local function placeBuildable(templateName, partName, position)
	local template = magic:FindFirstChild(templateName)
	if not template then
		return
	end

	local clone = template:Clone()
	local mainPart = clone:FindFirstChild(partName, true)
	if mainPart and mainPart:IsA("BasePart") then
		mainPart.Transparency = 0.5
		mainPart.CanCollide = false
	end
	clone.Parent = workspace
	clone:PivotTo(CFrame.new(position))

	task.delay(1.25, function()
		if mainPart and mainPart.Parent then
			mainPart.Transparency = 0
			mainPart.CanCollide = true
		end
	end)
end

local function tagHumanoid(humanoid, player)
	if not humanoid or not player then
		return
	end

	local creator = humanoid:FindFirstChild("creator") or Instance.new("ObjectValue")
	creator.Name = "creator"
	creator.Value = player
	creator.Parent = humanoid
	Debris:AddItem(creator, 4)
end

local function spawnSuper(player, position)
	local character, root = getCharacterRoot(player)
	if not character or not root or typeof(position) ~= "Vector3" then
		return
	end
	if (position - root.Position).Magnitude > MAX_SUPER_DISTANCE then
		return
	end

	local template = magic:FindFirstChild("Superior_Magicions")
	if not template then
		return
	end

	local function explodeAt(target, clone)
		local explosion = Instance.new("Explosion")
		explosion.Position = target
		explosion.BlastRadius = SUPER_RADIUS
		explosion.BlastPressure = 100
		explosion.DestroyJointRadiusPercent = 0
		explosion.Parent = workspace
		explosion.Hit:Connect(function(part)
			local victimCharacter = part.Parent
			local humanoid = victimCharacter and victimCharacter:FindFirstChild("Humanoid")
			if not humanoid or humanoid.Health <= 0 then
				return
			end

			local victimPlayer = game.Players:GetPlayerFromCharacter(victimCharacter)
			if victimPlayer == player then
				return
			end

			tagHumanoid(humanoid, player)
			humanoid:TakeDamage(SUPER_DAMAGE)
		end)

		if clone and clone.Parent then
			clone:Destroy()
		end
	end

	for _ = 1, SUPER_PROJECTILE_COUNT do
		task.delay(math.random() * 1.4, function()
			if not player.Parent then
				return
			end

			local clone = template:Clone()
			clone.Parent = workspace
			setOwner(clone, player)

			local offset = Vector3.new(math.random(-33, 33), 0, math.random(-33, 33))
			local target = position + offset
			local spawnPosition = target + Vector3.new(0, 75, 0)
			clone:PivotTo(CFrame.new(spawnPosition))

			local visual = clone:FindFirstChildWhichIsA("BasePart", true)
			if visual then
				local tween = TweenService:Create(visual, TweenInfo.new(0.9, Enum.EasingStyle.Linear), {CFrame = CFrame.new(target)})
				tween:Play()
			end

			task.delay(0.95, function()
				if not clone.Parent then
					return
				end

				explodeAt(target, clone)
			end)

			Debris:AddItem(clone, 3)
		end)
	end
end

fireballEvent.OnServerEvent:Connect(function(player)
	if canCast(player, "FireBall") then
		local character = player.Character
		spawnFireball(character)
	end
end)

spikesEvent.OnServerEvent:Connect(function(player, position)
	if not canCast(player, "Spikes") then
		return
	end
	local result = rayToGround(player, position, MAX_BUILD_DISTANCE)
	if result then
		spawnSpikes(player, result.Position)
	end
end)

wallEvent.OnServerEvent:Connect(function(player, position)
	if not canCast(player, "Wall") then
		return
	end
	local result = rayToGround(player, position, MAX_BUILD_DISTANCE)
	if result then
		placeBuildable("wall", "Building_wall", result.Position)
	end
end)

floorEvent.OnServerEvent:Connect(function(player, position)
	if not canCast(player, "Floor") then
		return
	end
	local result = rayToGround(player, position, MAX_BUILD_DISTANCE)
	if result then
		placeBuildable("floor", "Building_floor", result.Position)
	end
end)

stairsEvent.OnServerEvent:Connect(function(player, position)
	if not canCast(player, "Stairs") then
		return
	end
	local result = rayToGround(player, position, MAX_BUILD_DISTANCE)
	if result then
		placeBuildable("stairs", "Building_stairs", result.Position)
	end
end)

iceArrowEvent.OnServerEvent:Connect(function(player)
	if canCast(player, "IceArrow") then
		spawnIceArrow(player.Character)
	end
end)

superEvent.OnServerEvent:Connect(function(player, position)
	if canCast(player, "Super") then
		spawnSuper(player, position)
	end
end)

npcArrowEvent.Event:Connect(function(character)
	spawnIceArrow(character)
end)

npcBallEvent.Event:Connect(function(character)
	spawnFireball(character)
end)

npcSpikesEvent.Event:Connect(function(character, root)
	if root then
		spawnSpikes(character, root.Position - Vector3.new(0, 4, 0))
	end
end)
''',
    "ReplicatedStorage/Magic/FireBall_Prefab/FireBallBehaviour": r'''local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local model = script.Parent
local fireball = model:WaitForChild("FireBall")
local speed = 70
local gravity = 30
local fallSpeed = -45
local groundY = 12
local exploded = false

local function tagHumanoid(humanoid)
	local ownerId = model:GetAttribute("OwnerId")
	if not ownerId then
		return
	end

	local player = game.Players:GetPlayerByUserId(ownerId)
	if not player then
		return
	end

	local creator = humanoid:FindFirstChild("creator") or Instance.new("ObjectValue")
	creator.Name = "creator"
	creator.Value = player
	creator.Parent = humanoid
	Debris:AddItem(creator, 4)
end

local function explode()
	if exploded or not model.Parent then
		return
	end
	exploded = true

	local explosion = Instance.new("Explosion")
	explosion.Position = fireball.Position
	explosion.BlastPressure = 120
	explosion.BlastRadius = 18
	explosion.DestroyJointRadiusPercent = 0
	explosion.Parent = workspace
	explosion.Hit:Connect(function(part)
		local character = part.Parent
		local humanoid = character and character:FindFirstChild("Humanoid")
		if humanoid and humanoid.Health > 0 then
			tagHumanoid(humanoid)
		end
	end)

	model:Destroy()
end

local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
params.FilterDescendantsInstances = {model}

local connection
connection = RunService.Heartbeat:Connect(function(dt)
	if not model.Parent then
		connection:Disconnect()
		return
	end

	fallSpeed += gravity * dt
	local move = Vector3.new(0, -fallSpeed * dt, -speed * dt)
	fireball.CFrame = fireball.CFrame * CFrame.new(move)

	if fireball.Position.Y <= groundY then
		explode()
		return
	end

	local hit = workspace:Raycast(fireball.Position, fireball.CFrame.LookVector * 3, params)
	if hit and not hit.Instance:IsDescendantOf(model) then
		explode()
	end
end)

Debris:AddItem(model, 8)
''',
    "ReplicatedStorage/Magic/IceArrowPrefab/IceArrowBehaviour": r'''local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local model = script.Parent
local arrow = model:WaitForChild("Arrow")
local speed = 85
local damage = 20
local freezeTime = 1.75
local hitOnce = false

local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
params.FilterDescendantsInstances = {model}

local function ownerPlayer()
	local ownerId = model:GetAttribute("OwnerId")
	if ownerId then
		return game.Players:GetPlayerByUserId(ownerId)
	end
	return nil
end

local function tagHumanoid(humanoid, player)
	if not player then
		return
	end
	local creator = humanoid:FindFirstChild("creator") or Instance.new("ObjectValue")
	creator.Name = "creator"
	creator.Value = player
	creator.Parent = humanoid
	Debris:AddItem(creator, 4)
end

local function hit(part)
	if hitOnce or not model.Parent then
		return
	end
	hitOnce = true

	local character = part.Parent
	local humanoid = character and character:FindFirstChild("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local owner = ownerPlayer()

	if humanoid and humanoid.Health > 0 then
		local victimPlayer = game.Players:GetPlayerFromCharacter(character)
		if not owner or victimPlayer ~= owner then
			tagHumanoid(humanoid, owner)
			humanoid:TakeDamage(damage)
			if root then
				root.Anchored = true
				task.delay(freezeTime, function()
					if root.Parent then
						root.Anchored = false
					end
				end)
			end
		end
	end

	model:Destroy()
end

local connection
connection = RunService.Heartbeat:Connect(function(dt)
	if not model.Parent then
		connection:Disconnect()
		return
	end

	local distance = speed * dt
	local direction = -arrow.CFrame.UpVector * distance
	local result = workspace:Raycast(arrow.Position, direction, params)
	if result then
		hit(result.Instance)
		return
	end

	model:PivotTo(model:GetPivot() + direction)
end)

Debris:AddItem(model, 6)
''',
    "ReplicatedStorage/Magic/Spikes_Prefab/SpikesBehaviour": r'''local Debris = game:GetService("Debris")

local model = script.Parent
local spikes = model:WaitForChild("Spikes")
local damage = 30
local cooldown = 1.5
local lastHit = {}

local function ownerPlayer()
	local ownerId = model:GetAttribute("OwnerId")
	if ownerId then
		return game.Players:GetPlayerByUserId(ownerId)
	end
	return nil
end

local function tagHumanoid(humanoid, player)
	if not player then
		return
	end
	local creator = humanoid:FindFirstChild("creator") or Instance.new("ObjectValue")
	creator.Name = "creator"
	creator.Value = player
	creator.Parent = humanoid
	Debris:AddItem(creator, 4)
end

spikes.Touched:Connect(function(hit)
	local character = hit.Parent
	local humanoid = character and character:FindFirstChild("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return
	end

	local now = os.clock()
	if lastHit[humanoid] and now - lastHit[humanoid] < cooldown then
		return
	end
	lastHit[humanoid] = now

	local owner = ownerPlayer()
	local victim = game.Players:GetPlayerFromCharacter(character)
	if owner and victim == owner then
		return
	end

	tagHumanoid(humanoid, owner)
	humanoid:TakeDamage(damage)
end)

Debris:AddItem(model, 6)
''',
    "ServerScriptService/NPCspawnScript": r'''local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local npcTemplates = ReplicatedStorage:WaitForChild("Rigs"):GetChildren()
local world = Workspace:WaitForChild("World")
local spawnParts = world:WaitForChild("SpawnPartsFolder"):GetChildren()
local rigsFolder = world:WaitForChild("Rigs")
local spawnEvent = ReplicatedStorage:WaitForChild("Events"):WaitForChild("SpawnEvent")

local function chooseFreeSpawn()
	local free = {}
	for _, part in ipairs(spawnParts) do
		local occupied = part:FindFirstChild("occupied")
		if occupied and occupied.Value == false then
			table.insert(free, part)
		end
	end
	if #free == 0 then
		return nil
	end
	return free[math.random(1, #free)]
end

local function spawnNpc(template)
	local spawnPart = chooseFreeSpawn()
	if not spawnPart then
		return nil
	end

	local occupied = spawnPart:FindFirstChild("occupied")
	if occupied then
		occupied.Value = true
	end

	local clone = template:Clone()
	clone.Parent = rigsFolder
	clone:PivotTo(spawnPart.CFrame)

	local partObj = Instance.new("ObjectValue")
	partObj.Name = "PartTo"
	partObj.Value = spawnPart
	partObj.Parent = clone

	local humanoid = clone:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.Died:Connect(function()
			if occupied then
				occupied.Value = false
			end
		end)
	end

	return clone
end

for _, template in ipairs(npcTemplates) do
	if template:IsA("Model") then
		spawnNpc(template)
	end
end

spawnEvent.Event:Connect(function()
	local candidates = {}
	for _, template in ipairs(npcTemplates) do
		if template:IsA("Model") then
			table.insert(candidates, template)
		end
	end
	if #candidates > 0 then
		spawnNpc(candidates[math.random(1, #candidates)])
	end
end)
''',
    "StarterGui/ShopGui/ShopFrame/ApplesFrame/Cost/AppleSellScript": r'''local cost = script.Parent
local each = cost.Parent:WaitForChild("TextLabel1")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local events = ReplicatedStorage:WaitForChild("Events")
local buyEvent = events:WaitForChild("AppleBuyEv")
local sellEvent = events:WaitForChild("AppleSellEv")
local appleTemplate = ReplicatedStorage:WaitForChild("Apple")

local function updatePrice()
	local costValue = math.random(25, 75)
	cost.Value = costValue
	each.Text = costValue .. "$ each"
end

updatePrice()
task.spawn(function()
	while script.Parent do
		task.wait(30)
		updatePrice()
	end
end)

buyEvent.OnServerEvent:Connect(function(player)
	local money = player:FindFirstChild("money")
	if not money or money.Value < cost.Value then
		return
	end

	money.Value -= cost.Value
	local clone = appleTemplate:Clone()
	clone.Parent = player:WaitForChild("Backpack")
end)

sellEvent.OnServerEvent:Connect(function(player)
	local backpack = player:FindFirstChild("Backpack")
	local apple = backpack and backpack:FindFirstChild("Apple")
	if not apple then
		return
	end

	local money = player:FindFirstChild("money")
	if money then
		money.Value += cost.Value
	end
	apple:Destroy()
end)
''',
    "StarterGui/ShopGui/Shopping": r'''local player = game.Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local gui = script.Parent
local frame = gui:WaitForChild("ShopFrame")
local sellButton = frame:WaitForChild("ApplesFrame"):WaitForChild("SellButton")
local openButton = gui:WaitForChild("OpenButton")

local moneyGui = player.PlayerGui:WaitForChild("MoneyGui"):WaitForChild("MoneyGenFrame")
local manaGui = player.PlayerGui:WaitForChild("ManaGui"):WaitForChild("ManaGenFrame")
local skillGui = player.PlayerGui:WaitForChild("SkillGui")

local events = ReplicatedStorage:WaitForChild("Events")
local buyEvent = events:WaitForChild("BuyEvent")
local moneyGenEvent = events:WaitForChild("MoneyGenEvent")
local manaGenEvent = events:WaitForChild("ManaGenEvent")
local appleBuyEvent = events:WaitForChild("AppleBuyEv")
local appleSellEvent = events:WaitForChild("AppleSellEv")

local moneyGeneratorStarted = false
local manaGeneratorStarted = false

local moneyLevel = moneyGui.TextLabel:WaitForChild("lvl")
local moneyDivision = moneyGui.TextLabel2:WaitForChild("Division")
local moneyCost = frame:WaitForChild("MoneyGenFrame"):WaitForChild("Cost")

local manaLevel = manaGui.TextLabel:WaitForChild("lvl")
local manaDivision = manaGui.TextLabel2:WaitForChild("Division")
local manaCost = frame:WaitForChild("ManaGenFrame"):WaitForChild("Cost")

local function canAfford(cost)
	local money = player:FindFirstChild("money")
	return money and money.Value >= cost
end

local function startMoneyGenerator()
	if moneyGeneratorStarted then
		return
	end
	moneyGeneratorStarted = true
	task.spawn(function()
		while moneyGeneratorStarted do
			moneyGenEvent:FireServer()
			task.wait(math.max(0.25, moneyDivision.Value))
		end
	end)
end

local function startManaGenerator()
	if manaGeneratorStarted then
		return
	end
	manaGeneratorStarted = true
	task.spawn(function()
		while manaGeneratorStarted do
			manaGenEvent:FireServer()
			task.wait(math.max(0.25, manaDivision.Value))
		end
	end)
end

local function setUnlocked(category, itemName)
	if category == "Skills" then
		local label = skillGui.Skills:FindFirstChild(itemName)
		if label then
			label.Visible = true
		end
	elseif category == "Buildings" then
		local label = skillGui.Buildings:FindFirstChild(itemName)
		if label then
			label.Visible = true
		end
	elseif category == "SuperFrame" then
		skillGui.SuperFrame.SuperiorLabel.Visible = true
	end
end

openButton.MouseButton1Click:Connect(function()
	frame.Visible = not frame.Visible
	openButton.Text = frame.Visible and "Close Market" or "Open Market"
end)

for _, itemFrame in ipairs(frame:GetChildren()) do
	if itemFrame:IsA("Frame") then
		local buyButton = itemFrame:FindFirstChild("BuyButton")
		local costValue = itemFrame:FindFirstChild("Cost")
		local category = itemFrame:FindFirstChild("Cat")
		if buyButton and costValue and category then
			buyButton.MouseButton1Click:Connect(function()
				local cost = math.floor(tonumber(costValue.Value) or 0)
				if cost < 0 or not canAfford(cost) then
					return
				end

				if category.Value == "Apples" then
					appleBuyEvent:FireServer()
					return
				end

				if category.Value == "MoneyGenFrame" then
					moneyLevel.Value += 1
					moneyDivision.Value = math.max(0.25, moneyDivision.Value / 2)
					moneyCost.Value = math.floor(moneyCost.Value * 1.5)
					moneyCost.Parent.TextLabel.Text = "money generator cost " .. moneyCost.Value .. " $"
					moneyGui.TextLabel.Text = "Money gen lvl:" .. moneyLevel.Value
					moneyGui.TextLabel2.Text = "Earns 1$/" .. moneyDivision.Value .. "s"
					startMoneyGenerator()
				elseif category.Value == "ManaGenFrame" then
					manaLevel.Value += 1
					manaDivision.Value = math.max(0.25, manaDivision.Value / 2)
					manaCost.Value = math.floor(manaCost.Value * 1.5)
					manaCost.Parent.TextLabel.Text = "mana generator cost " .. manaCost.Value .. " $"
					manaGui.TextLabel.Text = "Mana gen lvl:" .. manaLevel.Value
					manaGui.TextLabel2.Text = "Earns 1 Mana/" .. manaDivision.Value .. "s"
					startManaGenerator()
				elseif category.Value == "SuperFrame" then
					setUnlocked("SuperFrame")
					itemFrame:Destroy()
				else
					local nameValue = itemFrame:FindFirstChild("Name")
					if nameValue then
						setUnlocked(category.Value, nameValue.Value)
					end
					itemFrame:Destroy()
				end

				buyEvent:FireServer(cost)
				if buyButton.Parent then
					buyButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
					buyButton.Text = "Upgrade"
					buyButton.TextScaled = true
				end
			end)
		end
	end
end

sellButton.MouseButton1Click:Connect(function()
	appleSellEvent:FireServer()
end)
''',
    "StarterGui/ManaGui/ManaGenFrame/LocalScript": r'''local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera

local palette = {
	panel = Color3.fromRGB(24, 28, 34),
	panelSoft = Color3.fromRGB(36, 42, 50),
	text = Color3.fromRGB(245, 247, 250),
	muted = Color3.fromRGB(180, 190, 202),
	accent = Color3.fromRGB(0, 170, 255),
	gold = Color3.fromRGB(255, 202, 88),
	good = Color3.fromRGB(83, 214, 141),
	danger = Color3.fromRGB(255, 99, 99),
}

local function ensureCorner(instance, radius)
	local corner = instance:FindFirstChildOfClass("UICorner")
	if not corner then
		corner = Instance.new("UICorner")
		corner.Parent = instance
	end
	corner.CornerRadius = UDim.new(0, radius)
end

local function ensureStroke(instance, color, thickness, transparency)
	local stroke = instance:FindFirstChildOfClass("UIStroke")
	if not stroke then
		stroke = Instance.new("UIStroke")
		stroke.Parent = instance
	end
	stroke.Color = color
	stroke.Thickness = thickness
	stroke.Transparency = transparency
end

local function styleText(object)
	object.Font = Enum.Font.GothamMedium
	object.TextColor3 = palette.text
	object.TextWrapped = true
	object.TextScaled = true
	object.TextTruncate = Enum.TextTruncate.AtEnd
end

local function styleButton(button)
	styleText(button)
	button.AutoButtonColor = true
	button.BackgroundColor3 = palette.accent
	button.BackgroundTransparency = 0
	ensureCorner(button, 8)
	ensureStroke(button, Color3.fromRGB(255, 255, 255), 1, 0.82)
end

local function styleFrame(frame)
	if frame.Name:find("Bar") or frame.Name == "CD" then
		ensureCorner(frame, 6)
		return
	end

	if frame:IsA("ScrollingFrame") then
		frame.ScrollBarThickness = 8
		frame.ScrollBarImageColor3 = palette.accent
	end

	frame.BackgroundColor3 = palette.panel
	frame.BackgroundTransparency = math.min(frame.BackgroundTransparency, 0.12)
	ensureCorner(frame, 8)
	ensureStroke(frame, Color3.fromRGB(255, 255, 255), 1, 0.9)
end

local function styleObject(object)
	if object:IsA("TextButton") then
		styleButton(object)
	elseif object:IsA("TextLabel") then
		styleText(object)
		if object.Name:lower():find("coins") then
			object.TextColor3 = palette.gold
		end
	elseif object:IsA("Frame") or object:IsA("ScrollingFrame") then
		styleFrame(object)
	end
end

local function addResponsiveScale(screenGui)
	local scale = screenGui:FindFirstChild("ResponsiveScale")
	if not scale then
		scale = Instance.new("UIScale")
		scale.Name = "ResponsiveScale"
		scale.Parent = screenGui
	end

	local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
	local base = math.min(viewport.X / 1280, viewport.Y / 720)
	scale.Scale = math.clamp(base, 0.72, 1.08)
end

local function polishShop(shopGui)
	local frame = shopGui:FindFirstChild("ShopFrame")
	local openButton = shopGui:FindFirstChild("OpenButton")

	if frame and frame:IsA("GuiObject") then
		frame.AnchorPoint = Vector2.new(0.5, 0.5)
		frame.Position = UDim2.fromScale(0.5, 0.52)
		frame.Size = UDim2.fromScale(0.86, 0.78)
		frame.ClipsDescendants = true
	end

	if openButton and openButton:IsA("GuiObject") then
		openButton.AnchorPoint = Vector2.new(0, 1)
		openButton.Position = UDim2.new(0, 18, 1, -18)
		openButton.Size = UDim2.fromOffset(168, 44)
	end
end

local function polishSkillGui(skillGui)
	for _, frameName in ipairs({"Skills", "Buildings", "SuperFrame"}) do
		local frame = skillGui:FindFirstChild(frameName)
		if frame and frame:IsA("GuiObject") then
			frame.BackgroundTransparency = math.min(frame.BackgroundTransparency, 0.15)
		end
	end
end

local function polishAll()
	for _, object in ipairs(playerGui:GetDescendants()) do
		styleObject(object)
	end

	for _, gui in ipairs(playerGui:GetChildren()) do
		if gui:IsA("ScreenGui") then
			gui.IgnoreGuiInset = false
			addResponsiveScale(gui)
		end
	end

	local shopGui = playerGui:FindFirstChild("ShopGui")
	if shopGui then
		polishShop(shopGui)
	end

	local skillGui = playerGui:FindFirstChild("SkillGui")
	if skillGui then
		polishSkillGui(skillGui)
	end
end

task.defer(polishAll)

playerGui.DescendantAdded:Connect(function(object)
	task.defer(function()
		if object.Parent then
			styleObject(object)
		end
	end)
end)

if camera then
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
		for _, gui in ipairs(playerGui:GetChildren()) do
			if gui:IsA("ScreenGui") then
				addResponsiveScale(gui)
			end
		end
	end)
end
''',
    "StarterPlayer/StarterPlayerScripts/Value": r'''local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local events = ReplicatedStorage:WaitForChild("Events")
local manaEvent = events:WaitForChild("MANAevent")
local hpEvent = events:WaitForChild("HPevent")

local player = Players.LocalPlayer
local valueGui = player.PlayerGui:WaitForChild("ValueGui")
local manaBackground = valueGui:WaitForChild("ManaBackGround")
local hpBackground = valueGui:WaitForChild("HPBackGround")

local manaText = manaBackground:WaitForChild("Persent")
local manaBar = manaBackground:WaitForChild("ManaBar")
local hpBar = hpBackground:WaitForChild("HPbar")
local hpText = hpBackground:WaitForChild("HPpersent")
local coinsLabel = valueGui:WaitForChild("Coins_Safe")

local function clampPercent(value)
	return math.clamp((tonumber(value) or 0) / 100, 0, 1)
end

local function tweenBar(bar, value)
	bar:TweenSize(UDim2.new(clampPercent(value), 0, 1, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Linear, 0.18, true)
end

manaEvent.OnClientEvent:Connect(function(mana, money)
	local manaValue = math.clamp(math.floor(tonumber(mana) or 0), 0, 100)
	local moneyValue = math.max(0, math.floor(tonumber(money) or 0))

	coinsLabel.Text = "Coins: " .. moneyValue .. "$"
	manaText.Text = manaValue .. " / 100"
	tweenBar(manaBar, manaValue)
end)

hpEvent.OnClientEvent:Connect(function(health)
	local hpValue = math.clamp(math.floor(tonumber(health) or 0), 0, 100)
	hpText.Text = hpValue .. " / 100"
	tweenBar(hpBar, hpValue)
end)
''',
    "StarterPlayer/StarterPlayerScripts/Input": r'''local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local events = ReplicatedStorage:WaitForChild("Events")

local remotes = {
	FireBall = events:WaitForChild("FireBallEvent"),
	Spikes = events:WaitForChild("SpikesEvent"),
	Floor = events:WaitForChild("FloorEvent"),
	Stairs = events:WaitForChild("StairsEvent"),
	Wall = events:WaitForChild("WallEvent"),
	IceArrow = events:WaitForChild("IceArrowEvent"),
	Super = events:WaitForChild("SuperEvent"),
}

local playerGui = player:WaitForChild("PlayerGui")
local skillsGui = playerGui:WaitForChild("SkillGui")
local buildingsFrame = skillsGui:WaitForChild("Buildings")
local skillsFrame = skillsGui:WaitForChild("Skills")

local labels = {
	FireBall = skillsFrame:WaitForChild("FireBallLabel"),
	Spikes = skillsFrame:WaitForChild("SpikesLabel"),
	IceArrow = skillsFrame:WaitForChild("ArrowLabel"),
	Wall = buildingsFrame:WaitForChild("WallLabel"),
	Floor = buildingsFrame:WaitForChild("FloorLabel"),
	Stairs = buildingsFrame:WaitForChild("StairsLabel"),
	Super = skillsGui:WaitForChild("SuperFrame"):WaitForChild("SuperiorLabel"),
}

local costs = {
	FireBall = 40,
	Spikes = 15,
	IceArrow = 35,
	Wall = 7,
	Floor = 10,
	Stairs = 12,
	Super = 100,
}

local cooldowns = {
	FireBall = 6.4,
	Spikes = 1.6,
	IceArrow = 3.2,
	Wall = 0.8,
	Floor = 0.8,
	Stairs = 0.8,
	Super = 12.8,
}

for _, label in pairs(labels) do
	label.Visible = false
end

local coolingDown = {}

local function mouseWorldPosition()
	return player:GetMouse().Hit.Position
end

local function hasMana(spell)
	local mana = player:FindFirstChild("Mana")
	return mana and mana.Value >= costs[spell]
end

local function showCooldown(label, seconds)
	local cd = label:FindFirstChild("CD")
	local stroke = label:FindFirstChildOfClass("UIStroke")
	if not cd then
		task.wait(seconds)
		return
	end

	cd.BackgroundTransparency = 0.2
	if stroke then
		stroke.Color = Color3.new(0, 0, 0)
	end

	local steps = math.max(1, math.floor(seconds / 0.1))
	for step = 1, steps do
		cd.BackgroundTransparency = 0.2 + 0.8 * (step / steps)
		task.wait(0.1)
	end

	cd.BackgroundTransparency = 1
	if stroke then
		stroke.Color = Color3.fromRGB(0, 85, 255)
	end
end

local function cast(spell, withPosition)
	local label = labels[spell]
	if not label or not label.Visible or coolingDown[spell] or not hasMana(spell) then
		return
	end

	coolingDown[spell] = true
	if withPosition then
		remotes[spell]:FireServer(mouseWorldPosition())
	else
		remotes[spell]:FireServer()
	end

	task.spawn(function()
		showCooldown(label, cooldowns[spell])
		coolingDown[spell] = nil
	end)
end

local keyMap = {
	[Enum.KeyCode.Q] = {"FireBall", false},
	[Enum.KeyCode.X] = {"Spikes", true},
	[Enum.KeyCode.C] = {"Wall", true},
	[Enum.KeyCode.R] = {"Floor", true},
	[Enum.KeyCode.F] = {"Stairs", true},
	[Enum.KeyCode.E] = {"IceArrow", false},
	[Enum.KeyCode.T] = {"Super", true},
}

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	local action = keyMap[input.KeyCode]
	if action then
		cast(action[1], action[2])
	end
end)
''',
}


SOURCE_TEXT_REPLACEMENTS = {
    "ReplicatedStorage/Rigs/Magicion/Magicion_Behaviour": {
        'local anim1 = "http://www.roblox.com/asset/?id=85972648923109"': 'local anim1 = "rbxassetid://180426354"',
    },
}


SCRIPT_SOURCE_OVERRIDES = {
    "StarterGui/ManaGui/ManaGenFrame/LocalScript": "-- UI styling is saved directly in StarterGui properties.",
}


BOOSTER_CONTROLLERS = {
    "Workspace/World/Boosters/Jump_Boosters/JumpBooster/Script": {
        "folder": "Workspace/World/Boosters/Jump_Boosters",
        "name": "JumpBoostersController",
        "source": r'''local JumpBoost = require(game:GetService("ServerScriptService").Module:WaitForChild("JumpBoostModule"))

local folder = script.Parent
local activeCharacters = {}

local function hook(part)
	if not part:IsA("BasePart") then
		return
	end

	part.Touched:Connect(function(hit)
		local character = hit.Parent
		local humanoid = character and character:FindFirstChild("Humanoid")
		if not humanoid or activeCharacters[character] then
			return
		end

		activeCharacters[character] = true
		JumpBoost.JumpBoostStart(character)
		task.delay(JumpBoost.BoostTime, function()
			if character.Parent then
				JumpBoost.JumpBoostEnd(character)
			end
			activeCharacters[character] = nil
		end)
	end)
end

for _, item in ipairs(folder:GetDescendants()) do
	hook(item)
end

folder.DescendantAdded:Connect(hook)
''',
    },
    "Workspace/World/Boosters/SpeedBoosters/SpeedBooster/Script": {
        "folder": "Workspace/World/Boosters/SpeedBoosters",
        "name": "SpeedBoostersController",
        "source": r'''local SpeedBoost = require(game:GetService("ServerScriptService").Module:WaitForChild("SpeedModule"))

local folder = script.Parent
local activeHumanoids = {}

local function hook(part)
	if not part:IsA("BasePart") then
		return
	end

	part.Touched:Connect(function(hit)
		local character = hit.Parent
		local humanoid = character and character:FindFirstChild("Humanoid")
		if not humanoid or activeHumanoids[humanoid] then
			return
		end

		activeHumanoids[humanoid] = true
		SpeedBoost.speedup(humanoid)
		task.delay(SpeedBoost.boost_time, function()
			if humanoid.Parent then
				SpeedBoost.speeddown(humanoid)
			end
			activeHumanoids[humanoid] = nil
		end)
	end)
end

for _, item in ipairs(folder:GetDescendants()) do
	hook(item)
end

folder.DescendantAdded:Connect(hook)
''',
    },
}


SUFFIX_SOURCE_REPLACEMENTS = {
    "/Apple/ServerSideHandler": r'''local tool = script.Parent
local biteEvent = tool:WaitForChild("BiteTaken")
local finishedEvent = tool:WaitForChild("AppleFinished")
local configs = require(tool:WaitForChild("Configurations"))

local MAX_BITES = 1
local biteCountByPlayer = {}

local function equippedBy(player)
	local character = player.Character
	return character and tool:IsDescendantOf(character)
end

biteEvent.OnServerEvent:Connect(function(player)
	if not equippedBy(player) then
		return
	end

	local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return
	end

	local count = biteCountByPlayer[player] or 0
	if count >= MAX_BITES then
		return
	end
	biteCountByPlayer[player] = count + 1

	humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + configs.appleHealthRegen)
end)

finishedEvent.OnServerEvent:Connect(function(player)
	if equippedBy(player) then
		tool:Destroy()
	end
end)
''',
    "/MoneyGetScript": r'''local rig = script.Parent
local humanoid = rig:WaitForChild("Humanoid")
local rewardValue = rig:FindFirstChild("Money_Give")
local reward = rewardValue and rewardValue.Value or 0
local spawnEvent = game:GetService("ReplicatedStorage").Events:WaitForChild("SpawnEvent")

local rewarded = false

humanoid.Died:Connect(function()
	if rewarded then
		return
	end
	rewarded = true

	local creator = humanoid:FindFirstChild("creator")
	local player = creator and creator.Value
	local money = player and player:FindFirstChild("money")
	if money then
		money.Value += reward
	end

	local partTo = rig:FindFirstChild("PartTo")
	local occupied = partTo and partTo.Value and partTo.Value:FindFirstChild("occupied")
	if occupied then
		occupied.Value = false
	end

	spawnEvent:Fire()
	task.delay(2, function()
		if rig.Parent then
			rig:Destroy()
		end
	end)
end)
''',
}


def direct_item_name(item: ET.Element) -> str:
    props = item.find("Properties")
    if props is None:
        return item.attrib.get("class", "")
    for child in props:
        if child.attrib.get("name") == "Name":
            return child.text or item.attrib.get("class", "")
    return item.attrib.get("class", "")


def source_node(item: ET.Element) -> ET.Element | None:
    props = item.find("Properties")
    if props is None:
        return None
    for child in props:
        if child.attrib.get("name") == "Source":
            return child
    return None


def set_direct_item_name(item: ET.Element, name: str) -> None:
    props = item.find("Properties")
    if props is None:
        raise RuntimeError("Item has no Properties node")
    for child in props:
        if child.attrib.get("name") == "Name":
            child.text = name
            return
    node = ET.Element("string", {"name": "Name"})
    node.text = name
    props.append(node)


def walk_items(parent: ET.Element, path: str = ""):
    for child in list(parent):
        if child.tag != "Item":
            continue
        name = direct_item_name(child)
        full_path = f"{path}/{name}" if path else name
        yield child, full_path
        yield from walk_items(child, full_path)


def walk_items_with_parent(parent: ET.Element, path: str = ""):
    for child in list(parent):
        if child.tag != "Item":
            continue
        name = direct_item_name(child)
        full_path = f"{path}/{name}" if path else name
        yield parent, child, full_path
        yield from walk_items_with_parent(child, full_path)


def main() -> None:
    ET.register_namespace("xmime", "http://www.w3.org/2005/05/xmlmime")
    ET.register_namespace("xsi", "http://www.w3.org/2001/XMLSchema-instance")

    tree = ET.parse(PLACE)
    root = tree.getroot()
    changed: list[str] = []

    for item, path in walk_items(root):
        replacement = SOURCES_BY_PATH.get(path)
        if replacement is None:
            continue
        node = source_node(item)
        if node is None:
            raise RuntimeError(f"Script at {path} has no Source property")
        node.text = replacement
        changed.append(path)

    suffix_changed: list[str] = []
    for item, path in walk_items(root):
        for suffix, replacement in SUFFIX_SOURCE_REPLACEMENTS.items():
            if not path.endswith(suffix):
                continue
            node = source_node(item)
            if node is None:
                continue
            node.text = replacement
            suffix_changed.append(path)
            break

    text_changed: list[str] = []
    for item, path in walk_items(root):
        replacements = SOURCE_TEXT_REPLACEMENTS.get(path)
        if not replacements:
            continue
        node = source_node(item)
        if node is None or node.text is None:
            continue
        original = node.text
        updated = original
        for old, new in replacements.items():
            updated = updated.replace(old, new)
        if updated != original:
            node.text = updated
            text_changed.append(path)

    override_changed: list[str] = []
    for item, path in walk_items(root):
        replacement = SCRIPT_SOURCE_OVERRIDES.get(path)
        if replacement is None:
            continue
        node = source_node(item)
        if node is None:
            continue
        node.text = replacement
        override_changed.append(path)

    missing = sorted(set(SOURCES_BY_PATH) - set(changed))
    if missing:
        raise RuntimeError("Missing script paths: " + ", ".join(missing))

    booster_changes: list[str] = []
    for old_script_path, config in BOOSTER_CONTROLLERS.items():
        matches = [(parent, item, path) for parent, item, path in walk_items_with_parent(root) if path == old_script_path]
        folders = [(parent, item, path) for parent, item, path in walk_items_with_parent(root) if path == config["folder"]]
        if len(folders) != 1:
            raise RuntimeError(f"Expected one folder at {config['folder']}, found {len(folders)}")
        folder_item = folders[0][1]

        existing = [
            (parent, item, path)
            for parent, item, path in walk_items_with_parent(root)
            if path == f"{config['folder']}/{config['name']}"
        ]
        if existing:
            node = source_node(existing[0][1])
            if node is None:
                raise RuntimeError(f"Booster controller {config['name']} has no Source")
            node.text = config["source"]
            booster_changes.append(f"{config['name']}: refreshed existing controller")
            continue

        if not matches:
            raise RuntimeError(f"Missing booster scripts at {old_script_path}")

        keep_parent, keep_script, _ = matches[0]
        keep_parent.remove(keep_script)
        set_direct_item_name(keep_script, config["name"])
        node = source_node(keep_script)
        if node is None:
            raise RuntimeError(f"Booster script at {old_script_path} has no Source")
        node.text = config["source"]
        folder_item.append(keep_script)

        removed = 0
        for parent, item, _ in matches[1:]:
            parent.remove(item)
            removed += 1
        booster_changes.append(f"{config['name']}: kept 1, removed {removed}")

    tree.write(PLACE, encoding="utf-8", xml_declaration=False)
    print("patched", len(changed), "scripts")
    for path in changed:
        print(path)
    print("suffix patched", len(suffix_changed), "scripts")
    for path in suffix_changed:
        print(path)
    print("text replacements", len(text_changed), "scripts")
    for path in text_changed:
        print(path)
    print("source overrides", len(override_changed), "scripts")
    for path in override_changed:
        print(path)
    print("booster controllers")
    for line in booster_changes:
        print(line)


if __name__ == "__main__":
    main()
