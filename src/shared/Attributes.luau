--!strict
-- Names of the Player attributes the server replicates to clients.

local Attributes = {
	Money = "Money",
	Mana = "Mana",
	MoneyGeneratorLevel = "MoneyGeneratorLevel",
	ManaGeneratorLevel = "ManaGeneratorLevel",
	-- Set on ReplicatedStorage: the current apple market price.
	ApplePrice = "ApplePrice",
}

function Attributes.unlocked(spellId: string): string
	return "Unlocked_" .. spellId
end

function Attributes.generatorLevel(generatorId: string): string
	if generatorId == "MoneyGenerator" then
		return Attributes.MoneyGeneratorLevel
	end
	return Attributes.ManaGeneratorLevel
end

return Attributes
