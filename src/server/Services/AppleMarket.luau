--!strict
--[[
	Apple trading. One market price for the whole server, changed on a timer,
	so players can buy low and sell high. Apples also drop from orchard trees.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Attributes = require(ReplicatedStorage.Shared.Attributes)
local Economy = require(ReplicatedStorage.Shared.Config.Economy)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local PlayerData = require(script.Parent.PlayerData)
local RateLimiter = require(script.Parent.Parent.Util.RateLimiter)

local APPLE_NAME = "Apple"

local config = Economy.apples
local random = Random.new()
local price = config.minPrice
local allowSell = RateLimiter.new(4, 6)

local AppleMarket = {}

local function reprice()
	price = random:NextInteger(config.minPrice, config.maxPrice)
	ReplicatedStorage:SetAttribute(Attributes.ApplePrice, price)
end

local function collectApples(container: Instance?, into: { Tool })
	if not container then
		return
	end
	for _, child in container:GetChildren() do
		if child.Name == APPLE_NAME and child:IsA("Tool") then
			table.insert(into, child)
		end
	end
end

-- Apples in the backpack plus the one the character may be holding.
local function carriedApples(player: Player): { Tool }
	local apples: { Tool } = {}
	collectApples(player:FindFirstChildOfClass("Backpack"), apples)
	collectApples(player.Character, apples)
	return apples
end

function AppleMarket.getPrice(): number
	return price
end

-- Called by ShopService after the generic purchase checks.
function AppleMarket.buy(player: Player)
	local backpack = player:FindFirstChildOfClass("Backpack")
	local template = ReplicatedStorage:FindFirstChild(APPLE_NAME)
	if not backpack or not (template and template:IsA("Tool")) then
		return
	end

	if #carriedApples(player) >= config.maxCarried then
		Remotes.Notify:FireClient(player, `You can carry at most {config.maxCarried} apples.`)
		return
	end
	if not PlayerData.trySpendMoney(player, price) then
		Remotes.Notify:FireClient(player, `An apple costs {price}$ right now.`)
		return
	end

	template:Clone().Parent = backpack
end

local function onSell(player: Player)
	if not allowSell(player) or not PlayerData.isLoaded(player) then
		return
	end

	local apple = carriedApples(player)[1]
	if not apple then
		Remotes.Notify:FireClient(player, "You have no apples to sell.")
		return
	end

	-- Remove the item before paying so a repeated request cannot sell it twice.
	apple:Destroy()
	PlayerData.addMoney(player, price)
end

function AppleMarket.start()
	reprice()
	Remotes.SellApple.OnServerEvent:Connect(onSell)

	task.spawn(function()
		while true do
			task.wait(config.repriceSeconds)
			reprice()
		end
	end)
end

return AppleMarket
