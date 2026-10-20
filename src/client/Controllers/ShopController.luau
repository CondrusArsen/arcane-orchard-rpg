--!strict
--[[
	Shop window. Renders prices from the shared Economy config and sends
	purchase requests by item id. It never decides whether a purchase
	succeeded: ownership and levels come back as Player attributes.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local Attributes = require(ReplicatedStorage.Shared.Attributes)
local Economy = require(ReplicatedStorage.Shared.Config.Economy)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Spells = require(ReplicatedStorage.Shared.Config.Spells)

local MESSAGE_SECONDS = 2.5
local OWNED_COLOR = Color3.fromRGB(70, 140, 90)

local player = Players.LocalPlayer

local ShopController = {}

type ItemLabels = {
	price: TextLabel?,
	detail: TextLabel?,
}

-- The place file names several labels "TextLabel", so classify them by their default text.
local function findLabels(frame: Instance): ItemLabels
	local labels: ItemLabels = {}
	for _, child in frame:GetChildren() do
		if child:IsA("TextLabel") then
			local text = string.lower(child.Text)
			if not labels.price and string.find(text, "cost", 1, true) then
				labels.price = child
			elseif not labels.detail and string.find(text, "mana", 1, true) then
				labels.detail = child
			end
		end
	end
	return labels
end

local function formatSeconds(seconds: number): string
	return string.format("%gs", math.floor(seconds * 100 + 0.5) / 100)
end

local function generatorLevel(item: Economy.ShopItem): number
	local level = player:GetAttribute(Attributes.generatorLevel(item.id))
	return if typeof(level) == "number" then level else 0
end

local function generatorDetail(item: Economy.ShopItem, level: number): string
	local generatorId: Economy.GeneratorId = if item.id == "MoneyGenerator" then "MoneyGenerator" else "ManaGenerator"
	local generator = Economy.generator(generatorId)
	local interval = Economy.generatorInterval(generatorId, level + 1)
	if level >= item.maxLevel or not interval then
		return "Max level"
	end
	if generatorId == "MoneyGenerator" then
		return `Next level: {generator.moneyPerTick}$ for {generator.manaPerTick} mana every {formatSeconds(interval)}`
	end
	return `Next level: +{generator.manaPerTick} mana every {formatSeconds(interval)}`
end

local function bindItem(item: Economy.ShopItem, frame: Instance)
	local buyButton = frame:FindFirstChild("BuyButton")
	if not (buyButton and buyButton:IsA("TextButton")) then
		warn(`[ShopController] {frame.Name} has no BuyButton`)
		return
	end
	local labels = findLabels(frame)

	buyButton.Activated:Connect(function()
		Remotes.PurchaseItem:FireServer(item.id)
	end)

	local function refresh()
		if item.kind == "Spell" then
			local owned = player:GetAttribute(Attributes.unlocked(item.id)) == true
			if labels.price then
				labels.price.Text = `{item.displayName} - {item.price}$`
			end
			local spell = Spells.definitions[item.id]
			if labels.detail and spell then
				labels.detail.Text = `Takes {spell.manaCost} mana, key {spell.key.Name}`
			end
			buyButton.Text = if owned then "Owned" else "Buy"
			buyButton.AutoButtonColor = not owned
			if owned then
				buyButton.BackgroundColor3 = OWNED_COLOR
			end
		elseif item.kind == "Generator" then
			local level = generatorLevel(item)
			local maxed = level >= item.maxLevel
			if labels.price then
				labels.price.Text = if maxed
					then `{item.displayName} - max level`
					else `{item.displayName} - {Economy.priceForLevel(item, level)}$`
			end
			if labels.detail then
				labels.detail.Text = generatorDetail(item, level)
			end
			buyButton.Text = if maxed then "Max" elseif level > 0 then "Upgrade" else "Buy"
		end
	end

	refresh()
	if item.kind == "Spell" then
		player:GetAttributeChangedSignal(Attributes.unlocked(item.id)):Connect(refresh)
	elseif item.kind == "Generator" then
		player:GetAttributeChangedSignal(Attributes.generatorLevel(item.id)):Connect(refresh)
	end
end

local function bindApples(frame: Instance)
	local priceLabel = frame:FindFirstChild("TextLabel1")
	local sellButton = frame:FindFirstChild("SellButton")

	local function refresh()
		local price = ReplicatedStorage:GetAttribute(Attributes.ApplePrice)
		if priceLabel and priceLabel:IsA("TextLabel") and typeof(price) == "number" then
			priceLabel.Text = `{price}$ each`
		end
	end
	refresh()
	ReplicatedStorage:GetAttributeChangedSignal(Attributes.ApplePrice):Connect(refresh)

	if sellButton and sellButton:IsA("TextButton") then
		sellButton.Activated:Connect(function()
			Remotes.SellApple:FireServer()
		end)
	end
end

function ShopController.start()
	local shopGui = player:WaitForChild("PlayerGui"):WaitForChild("ShopGui")
	local shopFrame = shopGui:WaitForChild("ShopFrame") :: GuiObject
	local openButton = shopGui:WaitForChild("OpenButton") :: TextButton
	local messageLabel = shopFrame:FindFirstChild("Welcome_Label")

	openButton.Activated:Connect(function()
		shopFrame.Visible = not shopFrame.Visible
		openButton.Text = if shopFrame.Visible then "Close Market" else "Open Market"
	end)

	for _, item in Economy.items do
		local frame = shopFrame:FindFirstChild(item.frame)
		if not frame then
			warn(`[ShopController] Shop frame "{item.frame}" not found`)
		elseif item.kind == "Apple" then
			bindItem(item, frame)
			bindApples(frame)
		else
			bindItem(item, frame)
		end
	end

	-- Server feedback (insufficient coins, unlocks): shown in the shop header while the
	-- shop is open, otherwise as a standard Roblox notification.
	local label = if messageLabel and messageLabel:IsA("TextLabel") then messageLabel else nil
	local defaultText = if label then label.Text else ""
	local messageId = 0
	Remotes.Notify.OnClientEvent:Connect(function(message: unknown)
		if typeof(message) ~= "string" then
			return
		end
		if label and shopFrame.Visible then
			messageId += 1
			local current = messageId
			label.Text = message
			task.delay(MESSAGE_SECONDS, function()
				if messageId == current then
					label.Text = defaultText
				end
			end)
		else
			pcall(function()
				StarterGui:SetCore("SendNotification", {
					Title = "Arcane Orchard",
					Text = message,
					Duration = MESSAGE_SECONDS,
				})
			end)
		end
	end)
end

return ShopController
