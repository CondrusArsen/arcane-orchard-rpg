--!strict
--[[
	Access to the art assets stored in the place file.

	Prefabs (ReplicatedStorage.Magic, ReplicatedStorage.Rigs) are treated as
	pure visuals: all behaviour lives in this codebase. Any server script left
	inside a prefab is removed on clone so it cannot run a second copy of the
	logic.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Prefabs = {}

-- Runtime folders under Workspace.
Prefabs.Folders = {
	Effects = "SpellEffects",
	Enemies = "Enemies",
	Buildables = "Buildables",
}

local folders: { [string]: Folder } = {}

-- Runtime container under Workspace, created on first use.
function Prefabs.workspaceFolder(name: string): Folder
	local existing = folders[name]
	if existing and existing.Parent then
		return existing
	end
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = workspace
	folders[name] = folder
	return folder
end

function Prefabs.stripServerScripts(root: Instance)
	for _, descendant in root:GetDescendants() do
		-- LocalScript inherits from Script, so compare the class name exactly.
		if descendant.ClassName == "Script" then
			descendant:Destroy()
		end
	end
end

function Prefabs.cloneModel(folderName: string, modelName: string): Model?
	local folder = ReplicatedStorage:FindFirstChild(folderName)
	local template = folder and folder:FindFirstChild(modelName)
	if not (template and template:IsA("Model")) then
		warn(`[Prefabs] Missing model ReplicatedStorage.{folderName}.{modelName}`)
		return nil
	end
	local clone = template:Clone()
	Prefabs.stripServerScripts(clone)
	return clone
end

-- Spell visuals: non-colliding and invisible to raycasts and overlap queries.
function Prefabs.cloneSpellVisual(modelName: string): Model?
	local clone = Prefabs.cloneModel("Magic", modelName)
	if not clone then
		return nil
	end
	for _, descendant in clone:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.CanQuery = false
			descendant.CanTouch = false
		end
	end
	return clone
end

return Prefabs
