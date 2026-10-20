--!strict
--[[
	One-time Studio step for places/ArcaneOrchardRPG.rbxlx.

	The place file still carries the scripts it was originally built with.
	Gameplay code now lives in src/ and is synced by Rojo, so this removes the
	in-place copies that would otherwise run alongside it. Paste the file into
	the Studio command bar (View > Command Bar), press Enter, then save.
	Safe to run more than once; it can be undone with Ctrl+Z.
]]

local ChangeHistoryService = game:GetService("ChangeHistoryService")

-- Scripts and value objects replaced by src/ (paths are relative to `game`).
local LEGACY_PATHS = {
	"ServerScriptService/MyFolder",
	"ServerScriptService/Module",
	"ServerScriptService/MoneyGenScript",
	"ServerScriptService/NPCspawnScript",
	"ServerScriptService/Time_of_day",
	"StarterPlayer/StarterPlayerScripts/Input",
	"StarterPlayer/StarterPlayerScripts/Value",
	"StarterPlayer/StarterCharacterScripts/HPscript",
	"StarterGui/ShopGui/Shopping",
	"StarterGui/ManaGui/ManaGenFrame/LocalScript",
	"StarterGui/ManaGui/ManaGenFrame/TextLabel/lvl",
	"StarterGui/ManaGui/ManaGenFrame/TextLabel2/Division",
	"StarterGui/ManaGui/Welcome/TextButton/LocalScript",
	"StarterGui/MoneyGui/MoneyGenFrame/TextLabel/lvl",
	"StarterGui/MoneyGui/MoneyGenFrame/TextLabel2/Division",
	"Workspace/World/Boosters/Jump_Boosters/JumpBoostersController",
	"Workspace/World/Boosters/SpeedBoosters/SpeedBoostersController",
	"ReplicatedStorage/Events",
}

-- Prefab folders whose server scripts are replaced by server/Spells and server/Npc.
local PREFAB_FOLDERS = { "Magic", "Rigs" }

-- Per-item price/category values in the shop; prices now come from shared/Config/Economy.
local SHOP_VALUE_NAMES = { Cost = true, Cat = true, Name = true }

local function resolve(path: string): Instance?
	local current: Instance? = game
	for _, name in string.split(path, "/") do
		current = current and current:FindFirstChild(name)
	end
	return current
end

local function childrenAt(path: string, deep: boolean): { Instance }
	local instance = resolve(path)
	if not instance then
		return {}
	end
	return if deep then instance:GetDescendants() else instance:GetChildren()
end

local recording = ChangeHistoryService:TryBeginRecording("Remove legacy scripts")
local removed = 0

for _, path in LEGACY_PATHS do
	local instance = resolve(path)
	if instance then
		instance:Destroy()
		removed += 1
	end
end

for _, folderName in PREFAB_FOLDERS do
	for _, descendant in childrenAt("ReplicatedStorage/" .. folderName, true) do
		if descendant.ClassName == "Script" then
			descendant:Destroy()
			removed += 1
		end
	end
end

for _, itemFrame in childrenAt("StarterGui/ShopGui/ShopFrame", false) do
	for _, child in itemFrame:GetChildren() do
		if SHOP_VALUE_NAMES[child.Name] and child:IsA("ValueBase") then
			child:Destroy()
			removed += 1
		end
	end
end

for _, spawnPart in childrenAt("Workspace/World/SpawnPartsFolder", false) do
	local occupied = spawnPart:FindFirstChild("occupied")
	if occupied then
		occupied:Destroy()
		removed += 1
	end
end

if recording then
	ChangeHistoryService:FinishRecording(recording, Enum.FinishRecordingOperation.Commit)
end
print(`[clean-place] Removed {removed} legacy instances. Save the place to keep the change.`)
