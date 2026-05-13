local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local events = ReplicatedStorage:WaitForChild("Events")

local remotes = {
	FireBall = events:WaitForChild("FireBallEvent"),
	Spikes = events:WaitForChild("SpikesEvent"),
	Floor = events:WaitForChild("FloorEvent"),
	Stairs = events:WaitForChild("StairsEvent"),
	Wall = events:WaitForChild("WallEvent"),
	IceArrow = events:WaitForChild("IceArrowEvent"),
	Super = events:WaitForChild("SuperEvent"),
}

local playerGui = player:WaitForChild("PlayerGui")
local skillsGui = playerGui:WaitForChild("SkillGui")
local buildingsFrame = skillsGui:WaitForChild("Buildings")
local skillsFrame = skillsGui:WaitForChild("Skills")

local labels = {
	FireBall = skillsFrame:WaitForChild("FireBallLabel"),
	Spikes = skillsFrame:WaitForChild("SpikesLabel"),
	IceArrow = skillsFrame:WaitForChild("ArrowLabel"),
	Wall = buildingsFrame:WaitForChild("WallLabel"),
	Floor = buildingsFrame:WaitForChild("FloorLabel"),
	Stairs = buildingsFrame:WaitForChild("StairsLabel"),
	Super = skillsGui:WaitForChild("SuperFrame"):WaitForChild("SuperiorLabel"),
}

local costs = {
	FireBall = 40,
	Spikes = 15,
	IceArrow = 35,
	Wall = 7,
	Floor = 10,
	Stairs = 12,
	Super = 100,
}

local cooldowns = {
	FireBall = 6.4,
	Spikes = 1.6,
	IceArrow = 3.2,
	Wall = 0.8,
	Floor = 0.8,
	Stairs = 0.8,
	Super = 12.8,
}

for _, label in pairs(labels) do
	label.Visible = false
end

local coolingDown = {}

local function mouseWorldPosition()
	return player:GetMouse().Hit.Position
end

local function hasMana(spell)
	local mana = player:FindFirstChild("Mana")
	return mana and mana.Value >= costs[spell]
end

local function showCooldown(label, seconds)
	local cd = label:FindFirstChild("CD")
	local stroke = label:FindFirstChildOfClass("UIStroke")
	if not cd then
		task.wait(seconds)
		return
	end

	cd.BackgroundTransparency = 0.2
	if stroke then
		stroke.Color = Color3.new(0, 0, 0)
	end

	local steps = math.max(1, math.floor(seconds / 0.1))
	for step = 1, steps do
		cd.BackgroundTransparency = 0.2 + 0.8 * (step / steps)
		task.wait(0.1)
	end

	cd.BackgroundTransparency = 1
	if stroke then
		stroke.Color = Color3.fromRGB(0, 85, 255)
	end
end

local function cast(spell, withPosition)
	local label = labels[spell]
	if not label or not label.Visible or coolingDown[spell] or not hasMana(spell) then
		return
	end

	coolingDown[spell] = true
	if withPosition then
		remotes[spell]:FireServer(mouseWorldPosition())
	else
		remotes[spell]:FireServer()
	end

	task.spawn(function()
		showCooldown(label, cooldowns[spell])
		coolingDown[spell] = nil
	end)
end

local keyMap = {
	[Enum.KeyCode.Q] = {"FireBall", false},
	[Enum.KeyCode.X] = {"Spikes", true},
	[Enum.KeyCode.C] = {"Wall", true},
	[Enum.KeyCode.R] = {"Floor", true},
	[Enum.KeyCode.F] = {"Stairs", true},
	[Enum.KeyCode.E] = {"IceArrow", false},
	[Enum.KeyCode.T] = {"Super", true},
}

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	local action = keyMap[input.KeyCode]
	if action then
		cast(action[1], action[2])
	end
end)
