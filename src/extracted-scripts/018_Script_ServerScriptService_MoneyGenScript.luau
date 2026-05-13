local ReplicatedStorage = game:GetService("ReplicatedStorage")
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
