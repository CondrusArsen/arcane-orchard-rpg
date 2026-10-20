--!strict
--[[
	Health, mana and coin bars plus the generator panels. Everything is driven
	by replicated state (Player attributes and the Humanoid), not by remotes.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Attributes = require(ReplicatedStorage.Shared.Attributes)
local Economy = require(ReplicatedStorage.Shared.Config.Economy)

local BAR_TWEEN = TweenInfo.new(0.18, Enum.EasingStyle.Linear)

local player = Players.LocalPlayer

local Hud = {}

local function numberAttribute(name: string): number
	local value = player:GetAttribute(name)
	return if typeof(value) == "number" then value else 0
end

local function setBar(bar: GuiObject, fraction: number)
	TweenService:Create(bar, BAR_TWEEN, { Size = UDim2.fromScale(math.clamp(fraction, 0, 1), 1) }):Play()
end

local function formatSeconds(seconds: number): string
	return string.format("%gs", math.floor(seconds * 100 + 0.5) / 100)
end

local function bindAttribute(name: string, callback: () -> ())
	callback()
	player:GetAttributeChangedSignal(name):Connect(callback)
end

local function bindStats(valueGui: Instance)
	local manaPanel = valueGui:WaitForChild("ManaBackGround")
	local manaBar = manaPanel:WaitForChild("ManaBar") :: GuiObject
	local manaText = manaPanel:WaitForChild("Persent") :: TextLabel
	local hpPanel = valueGui:WaitForChild("HPBackGround")
	local hpBar = hpPanel:WaitForChild("HPbar") :: GuiObject
	local hpText = hpPanel:WaitForChild("HPpersent") :: TextLabel
	local coins = valueGui:WaitForChild("Coins_Safe") :: TextLabel

	bindAttribute(Attributes.Mana, function()
		local mana = numberAttribute(Attributes.Mana)
		manaText.Text = `{mana} / {Economy.maxMana}`
		setBar(manaBar, mana / Economy.maxMana)
	end)

	bindAttribute(Attributes.Money, function()
		coins.Text = `Coins: {numberAttribute(Attributes.Money)}$`
	end)

	local function bindHumanoid(character: Model)
		local humanoid = character:WaitForChild("Humanoid") :: Humanoid
		local function refresh()
			local maxHealth = math.max(humanoid.MaxHealth, 1)
			hpText.Text = `{math.ceil(humanoid.Health)} / {math.ceil(maxHealth)}`
			setBar(hpBar, humanoid.Health / maxHealth)
		end
		refresh()
		humanoid.HealthChanged:Connect(refresh)
	end
	if player.Character then
		task.spawn(bindHumanoid, player.Character)
	end
	player.CharacterAdded:Connect(bindHumanoid)
end

local function bindGeneratorPanel(panel: Instance, generatorId: Economy.GeneratorId, title: string)
	local levelLabel = panel:WaitForChild("TextLabel") :: TextLabel
	local rateLabel = panel:WaitForChild("TextLabel2") :: TextLabel
	local generator = Economy.generator(generatorId)

	bindAttribute(Attributes.generatorLevel(generatorId), function()
		local level = numberAttribute(Attributes.generatorLevel(generatorId))
		levelLabel.Text = `{title} lvl: {level}`
		local interval = Economy.generatorInterval(generatorId, level)
		if not interval then
			rateLabel.Text = "Not built yet"
		elseif generatorId == "MoneyGenerator" then
			rateLabel.Text =
				`{generator.moneyPerTick}$ for {generator.manaPerTick} mana every {formatSeconds(interval)}`
		else
			rateLabel.Text = `+{generator.manaPerTick} mana every {formatSeconds(interval)}`
		end
	end)
end

local function bindWelcome(manaGui: Instance)
	local welcome = manaGui:FindFirstChild("Welcome")
	local close = welcome and welcome:FindFirstChildOfClass("TextButton")
	if welcome and close then
		close.Activated:Connect(function()
			welcome:Destroy()
		end)
	end
end

function Hud.start()
	local playerGui = player:WaitForChild("PlayerGui")
	bindStats(playerGui:WaitForChild("ValueGui"))

	local moneyGui = playerGui:WaitForChild("MoneyGui")
	bindGeneratorPanel(moneyGui:WaitForChild("MoneyGenFrame"), "MoneyGenerator", "Money gen")

	local manaGui = playerGui:WaitForChild("ManaGui")
	bindGeneratorPanel(manaGui:WaitForChild("ManaGenFrame"), "ManaGenerator", "Mana gen")
	bindWelcome(manaGui)
end

return Hud
