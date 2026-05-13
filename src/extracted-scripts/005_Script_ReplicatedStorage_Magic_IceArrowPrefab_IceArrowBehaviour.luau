local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local model = script.Parent
local arrow = model:WaitForChild("Arrow")
local speed = 85
local damage = 20
local freezeTime = 1.75
local hitOnce = false

local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
params.FilterDescendantsInstances = {model}

local function ownerPlayer()
	local ownerId = model:GetAttribute("OwnerId")
	if ownerId then
		return game.Players:GetPlayerByUserId(ownerId)
	end
	return nil
end

local function tagHumanoid(humanoid, player)
	if not player then
		return
	end
	local creator = humanoid:FindFirstChild("creator") or Instance.new("ObjectValue")
	creator.Name = "creator"
	creator.Value = player
	creator.Parent = humanoid
	Debris:AddItem(creator, 4)
end

local function hit(part)
	if hitOnce or not model.Parent then
		return
	end
	hitOnce = true

	local character = part.Parent
	local humanoid = character and character:FindFirstChild("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local owner = ownerPlayer()

	if humanoid and humanoid.Health > 0 then
		local victimPlayer = game.Players:GetPlayerFromCharacter(character)
		if not owner or victimPlayer ~= owner then
			tagHumanoid(humanoid, owner)
			humanoid:TakeDamage(damage)
			if root then
				root.Anchored = true
				task.delay(freezeTime, function()
					if root.Parent then
						root.Anchored = false
					end
				end)
			end
		end
	end

	model:Destroy()
end

local connection
connection = RunService.Heartbeat:Connect(function(dt)
	if not model.Parent then
		connection:Disconnect()
		return
	end

	local distance = speed * dt
	local direction = -arrow.CFrame.UpVector * distance
	local result = workspace:Raycast(arrow.Position, direction, params)
	if result then
		hit(result.Instance)
		return
	end

	model:PivotTo(model:GetPivot() + direction)
end)

Debris:AddItem(model, 6)
