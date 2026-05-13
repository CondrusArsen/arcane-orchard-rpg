local JumpBoost = require(game:GetService("ServerScriptService").Module:WaitForChild("JumpBoostModule"))

local folder = script.Parent
local activeCharacters = {}

local function hook(part)
	if not part:IsA("BasePart") then
		return
	end

	part.Touched:Connect(function(hit)
		local character = hit.Parent
		local humanoid = character and character:FindFirstChild("Humanoid")
		if not humanoid or activeCharacters[character] then
			return
		end

		activeCharacters[character] = true
		JumpBoost.JumpBoostStart(character)
		task.delay(JumpBoost.BoostTime, function()
			if character.Parent then
				JumpBoost.JumpBoostEnd(character)
			end
			activeCharacters[character] = nil
		end)
	end)
end

for _, item in ipairs(folder:GetDescendants()) do
	hook(item)
end

folder.DescendantAdded:Connect(hook)
