local tool = script.Parent
local biteEvent = tool:WaitForChild("BiteTaken")
local finishedEvent = tool:WaitForChild("AppleFinished")
local configs = require(tool:WaitForChild("Configurations"))

local MAX_BITES = 1
local biteCountByPlayer = {}

local function equippedBy(player)
	local character = player.Character
	return character and tool:IsDescendantOf(character)
end

biteEvent.OnServerEvent:Connect(function(player)
	if not equippedBy(player) then
		return
	end

	local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return
	end

	local count = biteCountByPlayer[player] or 0
	if count >= MAX_BITES then
		return
	end
	biteCountByPlayer[player] = count + 1

	humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + configs.appleHealthRegen)
end)

finishedEvent.OnServerEvent:Connect(function(player)
	if equippedBy(player) then
		tool:Destroy()
	end
end)
