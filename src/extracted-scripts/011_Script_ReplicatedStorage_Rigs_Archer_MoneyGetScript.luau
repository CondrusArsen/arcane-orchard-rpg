local rig = script.Parent
local humanoid = rig:WaitForChild("Humanoid")
local rewardValue = rig:FindFirstChild("Money_Give")
local reward = rewardValue and rewardValue.Value or 0
local spawnEvent = game:GetService("ReplicatedStorage").Events:WaitForChild("SpawnEvent")

local rewarded = false

humanoid.Died:Connect(function()
	if rewarded then
		return
	end
	rewarded = true

	local creator = humanoid:FindFirstChild("creator")
	local player = creator and creator.Value
	local money = player and player:FindFirstChild("money")
	if money then
		money.Value += reward
	end

	local partTo = rig:FindFirstChild("PartTo")
	local occupied = partTo and partTo.Value and partTo.Value:FindFirstChild("occupied")
	if occupied then
		occupied.Value = false
	end

	spawnEvent:Fire()
	task.delay(2, function()
		if rig.Parent then
			rig:Destroy()
		end
	end)
end)
