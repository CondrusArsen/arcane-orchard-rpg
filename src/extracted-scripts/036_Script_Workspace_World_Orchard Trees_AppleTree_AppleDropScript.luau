local tree = script.Parent
local configs = require(script.DropConfigurations)
local apples = tree.Apples:GetChildren()
local apple = script.Apple
apple.Parent = game.ServerStorage

while true do
	local waitTime = math.random(configs.MinWaitForApple, configs.MaxWaitForApple)
	wait(waitTime)
	local numApples = #tree.DroppedApples:GetChildren()
	if numApples < configs.MaxApplesAtATime then
		local applePos = apples[math.random(#apples)]
		local newApple = apple:Clone()
		newApple.Parent = script.Parent.DroppedApples
		newApple.Handle.CFrame = applePos.CFrame
		newApple.Handle.Anchored = false
		newApple.Handle.RotVelocity = Vector3.new(math.random(-1,1), math.random(-1,1), math.random(-1,1))
	end
end