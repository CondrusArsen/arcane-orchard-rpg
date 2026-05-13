local bellows = script.Parent
local hinge = bellows:WaitForChild("Bottom"):WaitForChild("HingeConstraint")
local firePart = bellows:WaitForChild("FirePart")
local fire = firePart:WaitForChild("Fire")
local sparks = firePart:WaitForChild("Sparks")

local fireSpeedMin = NumberRange.new(1)
local fireSpreadMin = 10
local fireRateMin = 50
local sparksSpeedMin = NumberRange.new(7)
local sparksRateMin = 10

local fireSpeedMax = NumberRange.new(5)
local fireSpreadMax = 20
local fireRateMax = 100
local sparksSpeedMax = NumberRange.new(10)
local sparksRateMax = 160

local duration = 1
local angleThreshold = 10

local canFlare = true
while wait(1/10) do
	if math.abs(hinge.CurrentAngle) < angleThreshold then
		if canFlare then
			canFlare = false
			fire.Speed = fireSpeedMax
			fire.VelocitySpread = fireSpreadMax
			fire.Rate = fireRateMax
			sparks.Speed = sparksSpeedMax
			sparks.Rate = sparksRateMax
			wait(duration)
			fire.Speed = fireSpeedMin
			fire.VelocitySpread = fireSpreadMin
			fire.Rate = fireRateMin
			sparks.Speed = sparksSpeedMin
			sparks.Rate = sparksRateMin
		end
	else
		canFlare = true
	end
end