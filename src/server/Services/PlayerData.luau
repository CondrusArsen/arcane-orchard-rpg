--!strict
--[[
	Owns every player's persistent state (money, mana, unlocked spells,
	generator levels) for the length of their session.

	- Other services mutate state only through this module; each mutation
	  updates the matching Player attribute, which replicates to the client.
	- Loads retry with backoff. If loading still fails, the player gets a
	  default profile that is flagged `canSave = false`, so a DataStore outage
	  can never overwrite real progress with starting values.
	- Saves use UpdateAsync with retries and run on leave, on an autosave
	  interval and in BindToClose.
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Attributes = require(ReplicatedStorage.Shared.Attributes)
local Economy = require(ReplicatedStorage.Shared.Config.Economy)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Spells = require(ReplicatedStorage.Shared.Config.Spells)

export type Profile = {
	money: number,
	mana: number,
	unlocked: { [string]: boolean },
	generators: { [string]: number },
}

type Session = {
	profile: Profile,
	-- False when the load failed (or DataStores are unavailable): never write this profile.
	canSave: boolean,
	dirty: boolean,
}

local STORE_NAME = "ArcaneOrchard_Players"
local DATA_VERSION = 1
local MAX_ATTEMPTS = 4
local AUTOSAVE_SECONDS = 60
local SHUTDOWN_TIMEOUT = 25
local MAX_MONEY = 1e9

-- Studio sessions run without persistence so local testing never touches live data.
local store: DataStore? = if RunService:IsStudio() then nil else DataStoreService:GetDataStore(STORE_NAME)

local sessions: { [Player]: Session } = {}
local pendingSaves = 0

local PlayerData = {}

local function keyFor(player: Player): string
	return `player_{player.UserId}`
end

local function defaultProfile(): Profile
	return {
		money = Economy.startingMoney,
		mana = Economy.startingMana,
		unlocked = {},
		generators = { MoneyGenerator = 0, ManaGenerator = 0 },
	}
end

local function readNumber(value: unknown, fallback: number, min: number, max: number): number
	if typeof(value) ~= "number" or value ~= value then
		return fallback
	end
	return math.clamp(value, min, max)
end

-- Saved data is untrusted input too (older versions, manual edits): validate every field.
local function fromSaved(data: unknown): Profile
	local profile = defaultProfile()
	if typeof(data) ~= "table" then
		return profile
	end
	local saved = data :: { [string]: unknown }

	profile.money = math.floor(readNumber(saved.money, profile.money, 0, MAX_MONEY))
	profile.mana = readNumber(saved.mana, profile.mana, 0, Economy.maxMana)

	local unlocked = saved.unlocked
	if typeof(unlocked) == "table" then
		for _, id in unlocked :: { unknown } do
			if typeof(id) == "string" and Spells.definitions[id] then
				profile.unlocked[id] = true
			end
		end
	end

	local generators = saved.generators
	if typeof(generators) == "table" then
		local levels = generators :: { [string]: unknown }
		for id in profile.generators do
			local maxLevel = Economy.items[id].maxLevel
			profile.generators[id] = math.floor(readNumber(levels[id], 0, 0, maxLevel))
		end
	end

	return profile
end

local function toSaved(profile: Profile)
	local unlocked = {}
	for id in profile.unlocked do
		table.insert(unlocked, id)
	end
	table.sort(unlocked)

	return {
		version = DATA_VERSION,
		money = profile.money,
		mana = math.floor(profile.mana),
		unlocked = unlocked,
		generators = table.clone(profile.generators),
	}
end

local function loadSaved(player: Player): (boolean, unknown)
	local dataStore = store
	if not dataStore then
		return true, nil
	end

	for attempt = 1, MAX_ATTEMPTS do
		local ok, result = pcall(function()
			return dataStore:GetAsync(keyFor(player))
		end)
		if ok then
			return true, result
		end
		warn(`[PlayerData] Load attempt {attempt} failed for {player.UserId}: {result}`)
		if attempt == MAX_ATTEMPTS or not player.Parent then
			break
		end
		task.wait(2 ^ attempt)
	end
	return false, nil
end

local function save(player: Player, session: Session)
	local dataStore = store
	if not dataStore or not session.canSave then
		return
	end

	local payload = toSaved(session.profile)
	session.dirty = false
	pendingSaves += 1

	for attempt = 1, MAX_ATTEMPTS do
		local ok, err = pcall(function()
			dataStore:UpdateAsync(keyFor(player), function(old)
				-- Never downgrade data written by a newer version of the game.
				if typeof(old) == "table" and typeof(old.version) == "number" and old.version > DATA_VERSION then
					return nil
				end
				return payload
			end)
		end)
		if ok then
			break
		end
		warn(`[PlayerData] Save attempt {attempt} failed for {player.UserId}: {err}`)
		if attempt == MAX_ATTEMPTS then
			session.dirty = true
		else
			task.wait(2 ^ attempt)
		end
	end

	pendingSaves -= 1
end

local function publishAll(player: Player, profile: Profile)
	player:SetAttribute(Attributes.Money, profile.money)
	player:SetAttribute(Attributes.Mana, math.floor(profile.mana))
	for id, level in profile.generators do
		player:SetAttribute(Attributes.generatorLevel(id), level)
	end
	for id in Spells.definitions do
		player:SetAttribute(Attributes.unlocked(id), profile.unlocked[id] == true)
	end
end

local function onPlayerAdded(player: Player)
	local ok, data = loadSaved(player)
	if not player.Parent then
		return
	end

	local session: Session = {
		profile = if ok then fromSaved(data) else defaultProfile(),
		canSave = ok and store ~= nil,
		dirty = false,
	}
	sessions[player] = session
	publishAll(player, session.profile)

	if not ok then
		Remotes.Notify:FireClient(player, "Your save could not be loaded. Progress in this session will not be saved.")
	end
end

local function onPlayerRemoving(player: Player)
	local session = sessions[player]
	if not session then
		return
	end
	sessions[player] = nil
	save(player, session)
end

local function onClose()
	for player, session in sessions do
		-- Remove first so PlayerRemoving (also fired during shutdown) does not save twice.
		sessions[player] = nil
		task.spawn(save, player, session)
	end

	local deadline = os.clock() + SHUTDOWN_TIMEOUT
	while pendingSaves > 0 and os.clock() < deadline do
		task.wait(0.1)
	end
end

local function getSession(player: Player): Session?
	return sessions[player]
end

local function markChanged(session: Session)
	session.dirty = true
end

-- Public API -----------------------------------------------------------------

function PlayerData.isLoaded(player: Player): boolean
	return sessions[player] ~= nil
end

function PlayerData.isUnlocked(player: Player, spellId: string): boolean
	local session = getSession(player)
	return session ~= nil and session.profile.unlocked[spellId] == true
end

function PlayerData.unlock(player: Player, spellId: string)
	local session = getSession(player)
	if not session or not Spells.definitions[spellId] then
		return
	end
	session.profile.unlocked[spellId] = true
	markChanged(session)
	player:SetAttribute(Attributes.unlocked(spellId), true)
end

function PlayerData.getMoney(player: Player): number
	local session = getSession(player)
	return if session then session.profile.money else 0
end

function PlayerData.addMoney(player: Player, amount: number)
	local session = getSession(player)
	if not session or amount <= 0 then
		return
	end
	local profile = session.profile
	profile.money = math.min(MAX_MONEY, profile.money + math.floor(amount))
	markChanged(session)
	player:SetAttribute(Attributes.Money, profile.money)
end

function PlayerData.trySpendMoney(player: Player, amount: number): boolean
	local session = getSession(player)
	if not session or amount < 0 or session.profile.money < amount then
		return false
	end
	local profile = session.profile
	profile.money -= amount
	markChanged(session)
	player:SetAttribute(Attributes.Money, profile.money)
	return true
end

local function setMana(player: Player, session: Session, value: number)
	local profile = session.profile
	local before = math.floor(profile.mana)
	profile.mana = math.clamp(value, 0, Economy.maxMana)
	local after = math.floor(profile.mana)
	if after ~= before then
		markChanged(session)
		player:SetAttribute(Attributes.Mana, after)
	end
end

function PlayerData.addMana(player: Player, amount: number)
	local session = getSession(player)
	if session and amount > 0 then
		setMana(player, session, session.profile.mana + amount)
	end
end

function PlayerData.trySpendMana(player: Player, amount: number): boolean
	local session = getSession(player)
	if not session or session.profile.mana < amount then
		return false
	end
	setMana(player, session, session.profile.mana - amount)
	return true
end

function PlayerData.getGeneratorLevel(player: Player, generatorId: string): number
	local session = getSession(player)
	return if session then session.profile.generators[generatorId] or 0 else 0
end

function PlayerData.setGeneratorLevel(player: Player, generatorId: string, level: number)
	local session = getSession(player)
	if not session or session.profile.generators[generatorId] == nil then
		return
	end
	session.profile.generators[generatorId] = level
	markChanged(session)
	player:SetAttribute(Attributes.generatorLevel(generatorId), level)
end

function PlayerData.start()
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end
	game:BindToClose(onClose)

	task.spawn(function()
		while true do
			task.wait(AUTOSAVE_SECONDS)
			for player, session in sessions do
				if session.dirty then
					task.spawn(save, player, session)
				end
			end
		end
	end)
end

return PlayerData
