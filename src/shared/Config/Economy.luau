--!strict
--[[
	Economy constants and shop catalogue.

	Prices live here and only here: the client uses them to render the shop,
	the server uses them to charge the player. The client never sends a price.
]]

export type GeneratorId = "MoneyGenerator" | "ManaGenerator"

export type GeneratorTuning = {
	baseInterval: number,
	manaPerTick: number,
	moneyPerTick: number,
}

export type ShopItem = {
	id: string,
	kind: "Spell" | "Generator" | "Apple",
	displayName: string,
	-- Price of the first purchase; generators multiply it by `priceGrowth` per level.
	price: number,
	priceGrowth: number,
	maxLevel: number,
	-- Frame inside StarterGui.ShopGui.ShopFrame that shows this item.
	frame: string,
}

local Economy = {
	startingMoney = 500,
	startingMana = 100,
	maxMana = 100,
	baseManaRegenPerSecond = 2,

	generators = {
		-- Converts mana into coins: every interval it takes `manaPerTick` and pays `moneyPerTick`.
		MoneyGenerator = {
			baseInterval = 20,
			manaPerTick = 1,
			moneyPerTick = 1,
		},
		-- Adds `manaPerTick` mana every interval on top of the base regeneration.
		ManaGenerator = {
			baseInterval = 2,
			manaPerTick = 1,
			moneyPerTick = 0,
		},
	} :: { MoneyGenerator: GeneratorTuning, ManaGenerator: GeneratorTuning },
	-- Each generator level halves the interval, down to this floor.
	minGeneratorInterval = 0.25,

	apples = {
		minPrice = 25,
		maxPrice = 75,
		repriceSeconds = 30,
		maxCarried = 10,
	},
}

local items: { [string]: ShopItem } = {
	FireBall = {
		id = "FireBall",
		kind = "Spell",
		displayName = "Fireball",
		price = 2000,
		priceGrowth = 1,
		maxLevel = 1,
		frame = "FireBallFrame",
	},
	IceArrow = {
		id = "IceArrow",
		kind = "Spell",
		displayName = "Ice Arrow",
		price = 1000,
		priceGrowth = 1,
		maxLevel = 1,
		frame = "ArrowFrame",
	},
	Spikes = {
		id = "Spikes",
		kind = "Spell",
		displayName = "Spikes",
		price = 650,
		priceGrowth = 1,
		maxLevel = 1,
		frame = "SpikesFrame",
	},
	Wall = {
		id = "Wall",
		kind = "Spell",
		displayName = "Wall",
		price = 275,
		priceGrowth = 1,
		maxLevel = 1,
		frame = "WallFrame",
	},
	Floor = {
		id = "Floor",
		kind = "Spell",
		displayName = "Floor",
		price = 250,
		priceGrowth = 1,
		maxLevel = 1,
		frame = "FloorFrame",
	},
	Stairs = {
		id = "Stairs",
		kind = "Spell",
		displayName = "Stairs",
		price = 300,
		priceGrowth = 1,
		maxLevel = 1,
		frame = "StairsFrame",
	},
	Super = {
		id = "Super",
		kind = "Spell",
		displayName = "Super Magic",
		price = 2500,
		priceGrowth = 1,
		maxLevel = 1,
		frame = "SuperiorFrame",
	},
	MoneyGenerator = {
		id = "MoneyGenerator",
		kind = "Generator",
		displayName = "Money generator",
		price = 100,
		priceGrowth = 1.5,
		maxLevel = 6,
		frame = "MoneyGenFrame",
	},
	ManaGenerator = {
		id = "ManaGenerator",
		kind = "Generator",
		displayName = "Mana generator",
		price = 1500,
		priceGrowth = 1.5,
		maxLevel = 3,
		frame = "ManaGenFrame",
	},
	Apple = {
		id = "Apple",
		kind = "Apple",
		displayName = "Apple",
		-- Apple prices float between `apples.minPrice` and `apples.maxPrice`.
		price = 0,
		priceGrowth = 1,
		maxLevel = math.huge,
		frame = "ApplesFrame",
	},
}

Economy.items = items

function Economy.getItem(id: unknown): ShopItem?
	if typeof(id) ~= "string" then
		return nil
	end
	return items[id]
end

-- Price of buying the next level when the player currently owns `ownedLevel`.
function Economy.priceForLevel(item: ShopItem, ownedLevel: number): number
	return math.floor(item.price * item.priceGrowth ^ ownedLevel)
end

function Economy.generator(id: GeneratorId): GeneratorTuning
	return if id == "MoneyGenerator" then Economy.generators.MoneyGenerator else Economy.generators.ManaGenerator
end

-- Seconds between generator ticks at a given level (0 means not owned).
function Economy.generatorInterval(id: GeneratorId, level: number): number?
	if level <= 0 then
		return nil
	end
	local base = Economy.generator(id).baseInterval
	return math.max(Economy.minGeneratorInterval, base / 2 ^ level)
end

return Economy
