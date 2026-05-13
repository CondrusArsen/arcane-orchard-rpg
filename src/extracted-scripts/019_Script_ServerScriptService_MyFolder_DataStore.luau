local Players = game:GetService("Players")
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
