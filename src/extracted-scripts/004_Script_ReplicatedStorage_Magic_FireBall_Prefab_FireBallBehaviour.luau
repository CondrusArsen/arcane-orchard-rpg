local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local model = script.Parent
local fireball = model:WaitForChild("FireBall")
local speed = 70
local gravity = 30
local fallSpeed = -45
local groundY = 12
local exploded = false

local function tagHumanoid(humanoid)
	local ownerId = model:GetAttribute("OwnerId")
	if not ownerId then
		return
	end

	local player = game.Players:GetPlayerByUserId(ownerId)
	if not player then
		return
	end

	local creator = humanoid:FindFirstChild("creator") or Instance.new("ObjectValue")
	creator.Name = "creator"
	creator.Value = player
	creator.Parent = humanoid
	Debris:AddItem(creator, 4)
end

local function explode()
	if exploded or not model.Parent then
		return
	end
	exploded = true

	local explosion = Instance.new("Explosion")
	explosion.Position = fireball.Position
	explosion.BlastPressure = 120
	explosion.BlastRadius = 18
	explosion.DestroyJointRadiusPercent = 0
	explosion.Parent = workspace
	explosion.Hit:Connect(function(part)
		local character = part.Parent
		local humanoid = character and character:FindFirstChild("Humanoid")
		if humanoid and humanoid.Health > 0 then
			tagHumanoid(humanoid)
		end
	end)

	model:Destroy()
end

local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
params.FilterDescendantsInstances = {model}

local connection
connection = RunService.Heartbeat:Connect(function(dt)
	if not model.Parent then
		connection:Disconnect()
		return
	end

	fallSpeed += gravity * dt
	local move = Vector3.new(0, -fallSpeed * dt, -speed * dt)
	fireball.CFrame = fireball.CFrame * CFrame.new(move)

	if fireball.Position.Y <= groundY then
		explode()
		return
	end

	local hit = workspace:Raycast(fireball.Position, fireball.CFrame.LookVector * 3, params)
	if hit and not hit.Instance:IsDescendantOf(model) then
		explode()
	end
end)

Debris:AddItem(model, 8)
