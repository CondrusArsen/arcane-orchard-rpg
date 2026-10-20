--!strict
--[[
	Validates and applies every purchase.

	The client only sends an item id. Price, ownership and level caps are all
	decided here from the shared Economy config and the server-side profile.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Economy = require(ReplicatedStorage.Shared.Config.Economy)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local AppleMarket = require(script.Parent.AppleMarket)
local PlayerData = require(script.Parent.PlayerData)
local RateLimiter = require(script.Parent.Parent.Util.RateLimiter)

local allowPurchase = RateLimiter.new(4, 6)

local ShopService = {}

local function notify(player: Player, message: string)
	Remotes.Notify:FireClient(player, message)
end

local function buySpell(player: Player, item: Economy.ShopItem)
	if PlayerData.isUnlocked(player, item.id) then
		notify(player, `{item.displayName} is already unlocked.`)
		return
	end

	local price = Economy.priceForLevel(item, 0)
	if not PlayerData.trySpendMoney(player, price) then
		notify(player, `{item.displayName} costs {price}$.`)
		return
	end

	PlayerData.unlock(player, item.id)
	notify(player, `{item.displayName} unlocked!`)
end

local function buyGeneratorLevel(player: Player, item: Economy.ShopItem)
	local level = PlayerData.getGeneratorLevel(player, item.id)
	if level >= item.maxLevel then
		notify(player, `{item.displayName} is at max level.`)
		return
	end

	local price = Economy.priceForLevel(item, level)
	if not PlayerData.trySpendMoney(player, price) then
		notify(player, `Next {item.displayName} level costs {price}$.`)
		return
	end

	PlayerData.setGeneratorLevel(player, item.id, level + 1)
	notify(player, `{item.displayName} upgraded to level {level + 1}.`)
end

local function onPurchase(player: Player, itemId: unknown)
	if not allowPurchase(player) or not PlayerData.isLoaded(player) then
		return
	end

	local item = Economy.getItem(itemId)
	if not item then
		return
	end

	if item.kind == "Spell" then
		buySpell(player, item)
	elseif item.kind == "Generator" then
		buyGeneratorLevel(player, item)
	elseif item.kind == "Apple" then
		AppleMarket.buy(player)
	end
end

function ShopService.start()
	Remotes.PurchaseItem.OnServerEvent:Connect(onPurchase)
end

return ShopService
