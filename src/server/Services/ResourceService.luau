--!strict
--[[
	Server-side resource ticking: base mana regeneration plus the money and
	mana generators. Generator levels are read from PlayerData, so the only
	way to speed them up is a validated purchase.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Economy = require(ReplicatedStorage.Shared.Config.Economy)
local PlayerData = require(script.Parent.PlayerData)

local TICK_SECONDS = 0.25
-- Upper bound on generator payouts per tick, in case the server hitches.
local MAX_PAYOUTS_PER_TICK = 8

local moneyTimers: { [Player]: number } = {}

local ResourceService = {}

local function manaPerSecond(player: Player): number
	local rate = Economy.baseManaRegenPerSecond
	local level = PlayerData.getGeneratorLevel(player, "ManaGenerator")
	local interval = Economy.generatorInterval("ManaGenerator", level)
	if interval then
		rate += Economy.generators.ManaGenerator.manaPerTick / interval
	end
	return rate
end

local function runMoneyGenerator(player: Player, dt: number)
	local level = PlayerData.getGeneratorLevel(player, "MoneyGenerator")
	local interval = Economy.generatorInterval("MoneyGenerator", level)
	if not interval then
		return
	end

	local elapsed = (moneyTimers[player] or 0) + dt
	local payouts = math.floor(elapsed / interval)
	moneyTimers[player] = elapsed - payouts * interval

	local generator = Economy.generators.MoneyGenerator
	for _ = 1, math.min(payouts, MAX_PAYOUTS_PER_TICK) do
		-- The money generator converts mana into coins and stalls when mana runs out.
		if not PlayerData.trySpendMana(player, generator.manaPerTick) then
			break
		end
		PlayerData.addMoney(player, generator.moneyPerTick)
	end
end

local function tick(dt: number)
	for _, player in Players:GetPlayers() do
		if PlayerData.isLoaded(player) then
			PlayerData.addMana(player, manaPerSecond(player) * dt)
			runMoneyGenerator(player, dt)
		end
	end
end

function ResourceService.start()
	Players.PlayerRemoving:Connect(function(player)
		moneyTimers[player] = nil
	end)

	task.spawn(function()
		local last = os.clock()
		while true do
			task.wait(TICK_SECONDS)
			local now = os.clock()
			tick(now - last)
			last = now
		end
	end)
end

return ResourceService
