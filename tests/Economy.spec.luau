--!strict
-- Balance-rule tests for the pure economy config. Run with the Luau CLI:
--   luau tests/Economy.spec.luau

-- The test runs under the plain Luau CLI, which resolves string paths.
-- selene: allow(incorrect_standard_library_use)
local Economy = require("../src/shared/Config/Economy")

local failures = 0

local function test(name: string, body: () -> ())
	local ok, err = pcall(function(): any
		body()
		return nil
	end)
	if ok then
		print(`ok   {name}`)
	else
		failures += 1
		print(`FAIL {name}: {err}`)
	end
end

local function expectEqual(actual: unknown, expected: unknown)
	if actual ~= expected then
		error(`expected {expected}, got {actual}`, 2)
	end
end

test("getItem rejects non-string and unknown ids", function()
	expectEqual(Economy.getItem(nil), nil)
	expectEqual(Economy.getItem(42), nil)
	expectEqual(Economy.getItem({}), nil)
	expectEqual(Economy.getItem("NotAnItem"), nil)
	expectEqual((Economy.getItem("FireBall") :: Economy.ShopItem).id, "FireBall")
end)

test("item ids match their keys and every purchasable item has a price", function()
	for key, item in Economy.items do
		expectEqual(item.id, key)
		if item.kind ~= "Apple" then
			assert(item.price > 0, `{key} has no price`)
			assert(item.maxLevel >= 1, `{key} cannot be bought`)
		end
	end
end)

test("generator price grows per level", function()
	local item = Economy.items.MoneyGenerator
	expectEqual(Economy.priceForLevel(item, 0), 100)
	expectEqual(Economy.priceForLevel(item, 1), 150)
	expectEqual(Economy.priceForLevel(item, 2), 225)
end)

test("spell price does not grow", function()
	local item = Economy.items.Spikes
	expectEqual(Economy.priceForLevel(item, 0), Economy.priceForLevel(item, 3))
end)

test("generator interval: none at level 0, halves per level, floored", function()
	expectEqual(Economy.generatorInterval("MoneyGenerator", 0), nil)
	expectEqual(Economy.generatorInterval("MoneyGenerator", 1), 10)
	expectEqual(Economy.generatorInterval("MoneyGenerator", 2), 5)
	expectEqual(Economy.generatorInterval("ManaGenerator", 10), Economy.minGeneratorInterval)
end)

test("apple price range is valid", function()
	local apples = Economy.apples
	assert(apples.minPrice > 0 and apples.minPrice <= apples.maxPrice, "bad apple price range")
end)

if failures > 0 then
	error(`{failures} test(s) failed`)
end
print("all economy tests passed")
