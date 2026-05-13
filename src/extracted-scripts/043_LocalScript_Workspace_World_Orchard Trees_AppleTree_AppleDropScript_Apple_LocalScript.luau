local player = game.Players.LocalPlayer
repeat wait() until player.Character and player.Character.Parent
local hum = player.Character:WaitForChild("Humanoid")
local handle = script.Parent:WaitForChild("Handle")
local sound = handle:WaitForChild("Sound")
local eating = false

-- setting up the correct animation --
local eatingAnimation
if hum.RigType == Enum.HumanoidRigType.R6 then
	eatingAnimation = script.Parent.TakeABiteR6
else
	eatingAnimation = script.Parent.TakeABiteR15
end
local eatingAnim = hum:LoadAnimation(eatingAnimation)

script.Parent.Activated:connect(function()
	if not eating then
		eating = true
		eatingAnim:Play()
		eatingAnim.KeyframeReached:Connect(function(keyFrame)
			if keyFrame == "Bite" then
				sound.TimePosition = 0.3
				sound:Play()
				wait(0.5)
				script.Parent.BiteTaken:FireServer()
			end
		end)
	end
end)

eatingAnim.Stopped:Connect(function()
	script.Parent.AppleFinished:FireServer()
end)