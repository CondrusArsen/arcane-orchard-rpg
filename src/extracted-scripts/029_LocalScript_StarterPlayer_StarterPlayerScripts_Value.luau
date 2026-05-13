local ReplicatedStorage = game:GetService("ReplicatedStorage")
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
