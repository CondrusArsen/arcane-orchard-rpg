local SpeedBoost = require(game:GetService("ServerScriptService").Module:WaitForChild("SpeedModule"))

local folder = script.Parent
local activeHumanoids = {}

local function hook(part)
	if not part:IsA("BasePart") then
		return
	end

	part.Touched:Connect(function(hit)
		local character = hit.Parent
		local humanoid = character and character:FindFirstChild("Humanoid")
		if not humanoid or activeHumanoids[humanoid] then
			return
		end

		activeHumanoids[humanoid] = true
		SpeedBoost.speedup(humanoid)
		task.delay(SpeedBoost.boost_time, function()
			if humanoid.Parent then
				SpeedBoost.speeddown(humanoid)
			end
			activeHumanoids[humanoid] = nil
		end)
	end)
end

for _, item in ipairs(folder:GetDescendants()) do
	hook(item)
end

folder.DescendantAdded:Connect(hook)
