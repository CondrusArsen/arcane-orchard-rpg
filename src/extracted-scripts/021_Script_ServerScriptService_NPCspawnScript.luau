local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local npcTemplates = ReplicatedStorage:WaitForChild("Rigs"):GetChildren()
local world = Workspace:WaitForChild("World")
local spawnParts = world:WaitForChild("SpawnPartsFolder"):GetChildren()
local rigsFolder = world:WaitForChild("Rigs")
local spawnEvent = ReplicatedStorage:WaitForChild("Events"):WaitForChild("SpawnEvent")

local function chooseFreeSpawn()
	local free = {}
	for _, part in ipairs(spawnParts) do
		local occupied = part:FindFirstChild("occupied")
		if occupied and occupied.Value == false then
			table.insert(free, part)
		end
	end
	if #free == 0 then
		return nil
	end
	return free[math.random(1, #free)]
end

local function spawnNpc(template)
	local spawnPart = chooseFreeSpawn()
	if not spawnPart then
		return nil
	end

	local occupied = spawnPart:FindFirstChild("occupied")
	if occupied then
		occupied.Value = true
	end

	local clone = template:Clone()
	clone.Parent = rigsFolder
	clone:PivotTo(spawnPart.CFrame)

	local partObj = Instance.new("ObjectValue")
	partObj.Name = "PartTo"
	partObj.Value = spawnPart
	partObj.Parent = clone

	local humanoid = clone:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.Died:Connect(function()
			if occupied then
				occupied.Value = false
			end
		end)
	end

	return clone
end

for _, template in ipairs(npcTemplates) do
	if template:IsA("Model") then
		spawnNpc(template)
	end
end

spawnEvent.Event:Connect(function()
	local candidates = {}
	for _, template in ipairs(npcTemplates) do
		if template:IsA("Model") then
			table.insert(candidates, template)
		end
	end
	if #candidates > 0 then
		spawnNpc(candidates[math.random(1, #candidates)])
	end
end)
