local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local events = ReplicatedStorage:WaitForChild("Events")
local magic = ReplicatedStorage:WaitForChild("Magic")

local fireballEvent = events:WaitForChild("FireBallEvent")
local spikesEvent = events:WaitForChild("SpikesEvent")
local wallEvent = events:WaitForChild("WallEvent")
local floorEvent = events:WaitForChild("FloorEvent")
local stairsEvent = events:WaitForChild("StairsEvent")
local iceArrowEvent = events:WaitForChild("IceArrowEvent")
local superEvent = events:WaitForChild("SuperEvent")

local npcArrowEvent = events:WaitForChild("NPC_arrow_Event")
local npcBallEvent = events:WaitForChild("NPC_ball_Event")
local npcSpikesEvent = events:WaitForChild("NPC_spikes_Event")

local MAX_BUILD_DISTANCE = 40
local MAX_SUPER_DISTANCE = 150
local SUPER_PROJECTILE_COUNT = 28
local SUPER_DAMAGE = 35
local SUPER_RADIUS = 11

local costs = {
	FireBall = 40,
	Spikes = 15,
	Wall = 7,
	Floor = 10,
	Stairs = 12,
	IceArrow = 35,
	Super = 100,
}
local cooldowns = {
	FireBall = 1.25,
	Spikes = 1.5,
	Wall = 0.75,
	Floor = 0.75,
	Stairs = 0.75,
	IceArrow = 1.75,
	Super = 10,
}

local lastCast = {}

local function getCharacterRoot(player)
	local character = player.Character
	if not character then
		return nil
	end
	return character, character:FindFirstChild("HumanoidRootPart")
end

local function canCast(player, spell)
	local mana = player:FindFirstChild("Mana")
	if not mana or mana.Value < costs[spell] then
		return false
	end

	local now = os.clock()
	lastCast[player] = lastCast[player] or {}
	if lastCast[player][spell] and now - lastCast[player][spell] < cooldowns[spell] then
		return false
	end

	lastCast[player][spell] = now
	mana.Value -= costs[spell]
	return true
end

local function rayToGround(player, position, maxDistance)
	if typeof(position) ~= "Vector3" then
		return nil
	end

	local _, root = getCharacterRoot(player)
	if not root or (position - root.Position).Magnitude > maxDistance then
		return nil
	end

	local ignoreList = {}
	for _, item in ipairs(workspace:GetDescendants()) do
		if item:IsA("Humanoid") and item.Parent then
			table.insert(ignoreList, item.Parent)
		end
	end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignoreList

	return workspace:Raycast(position + Vector3.new(0, 50, 0), Vector3.new(0, -200, 0), params)
end

local function setOwner(model, characterOrPlayer)
	local player = characterOrPlayer
	if typeof(characterOrPlayer) == "Instance" and not characterOrPlayer:IsA("Player") then
		player = game.Players:GetPlayerFromCharacter(characterOrPlayer)
	end

	if player then
		model:SetAttribute("OwnerId", player.UserId)
	end
end

local function spawnFireball(character)
	local _, root = character, character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end

	local clone = magic:WaitForChild("FireBall_Prefab"):Clone()
	clone.Parent = workspace
	setOwner(clone, character)
	clone:PivotTo(root.CFrame * CFrame.new(0, 0, -5))
	Debris:AddItem(clone, 8)
end

local function spawnIceArrow(character)
	local _, root = character, character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end

	local clone = magic:WaitForChild("IceArrowPrefab"):Clone()
	clone.Parent = workspace
	setOwner(clone, character)
	clone:PivotTo(root.CFrame * CFrame.new(0, 0, -5))
	Debris:AddItem(clone, 8)
end

local function spawnSpikes(owner, position)
	local clone = magic:WaitForChild("Spikes_Prefab"):Clone()
	clone.Parent = workspace
	setOwner(clone, owner)
	clone:PivotTo(CFrame.new(position + Vector3.new(0, 1, 0)))
	Debris:AddItem(clone, 7)
end

local function placeBuildable(templateName, partName, position)
	local template = magic:FindFirstChild(templateName)
	if not template then
		return
	end

	local clone = template:Clone()
	local mainPart = clone:FindFirstChild(partName, true)
	if mainPart and mainPart:IsA("BasePart") then
		mainPart.Transparency = 0.5
		mainPart.CanCollide = false
	end
	clone.Parent = workspace
	clone:PivotTo(CFrame.new(position))

	task.delay(1.25, function()
		if mainPart and mainPart.Parent then
			mainPart.Transparency = 0
			mainPart.CanCollide = true
		end
	end)
end

local function tagHumanoid(humanoid, player)
	if not humanoid or not player then
		return
	end

	local creator = humanoid:FindFirstChild("creator") or Instance.new("ObjectValue")
	creator.Name = "creator"
	creator.Value = player
	creator.Parent = humanoid
	Debris:AddItem(creator, 4)
end

local function spawnSuper(player, position)
	local character, root = getCharacterRoot(player)
	if not character or not root or typeof(position) ~= "Vector3" then
		return
	end
	if (position - root.Position).Magnitude > MAX_SUPER_DISTANCE then
		return
	end

	local template = magic:FindFirstChild("Superior_Magicions")
	if not template then
		return
	end

	local function explodeAt(target, clone)
		local explosion = Instance.new("Explosion")
		explosion.Position = target
		explosion.BlastRadius = SUPER_RADIUS
		explosion.BlastPressure = 100
		explosion.DestroyJointRadiusPercent = 0
		explosion.Parent = workspace
		explosion.Hit:Connect(function(part)
			local victimCharacter = part.Parent
			local humanoid = victimCharacter and victimCharacter:FindFirstChild("Humanoid")
			if not humanoid or humanoid.Health <= 0 then
				return
			end

			local victimPlayer = game.Players:GetPlayerFromCharacter(victimCharacter)
			if victimPlayer == player then
				return
			end

			tagHumanoid(humanoid, player)
			humanoid:TakeDamage(SUPER_DAMAGE)
		end)

		if clone and clone.Parent then
			clone:Destroy()
		end
	end

	for _ = 1, SUPER_PROJECTILE_COUNT do
		task.delay(math.random() * 1.4, function()
			if not player.Parent then
				return
			end

			local clone = template:Clone()
			clone.Parent = workspace
			setOwner(clone, player)

			local offset = Vector3.new(math.random(-33, 33), 0, math.random(-33, 33))
			local target = position + offset
			local spawnPosition = target + Vector3.new(0, 75, 0)
			clone:PivotTo(CFrame.new(spawnPosition))

			local visual = clone:FindFirstChildWhichIsA("BasePart", true)
			if visual then
				local tween = TweenService:Create(visual, TweenInfo.new(0.9, Enum.EasingStyle.Linear), {CFrame = CFrame.new(target)})
				tween:Play()
			end

			task.delay(0.95, function()
				if not clone.Parent then
					return
				end

				explodeAt(target, clone)
			end)

			Debris:AddItem(clone, 3)
		end)
	end
end

fireballEvent.OnServerEvent:Connect(function(player)
	if canCast(player, "FireBall") then
		local character = player.Character
		spawnFireball(character)
	end
end)

spikesEvent.OnServerEvent:Connect(function(player, position)
	if not canCast(player, "Spikes") then
		return
	end
	local result = rayToGround(player, position, MAX_BUILD_DISTANCE)
	if result then
		spawnSpikes(player, result.Position)
	end
end)

wallEvent.OnServerEvent:Connect(function(player, position)
	if not canCast(player, "Wall") then
		return
	end
	local result = rayToGround(player, position, MAX_BUILD_DISTANCE)
	if result then
		placeBuildable("wall", "Building_wall", result.Position)
	end
end)

floorEvent.OnServerEvent:Connect(function(player, position)
	if not canCast(player, "Floor") then
		return
	end
	local result = rayToGround(player, position, MAX_BUILD_DISTANCE)
	if result then
		placeBuildable("floor", "Building_floor", result.Position)
	end
end)

stairsEvent.OnServerEvent:Connect(function(player, position)
	if not canCast(player, "Stairs") then
		return
	end
	local result = rayToGround(player, position, MAX_BUILD_DISTANCE)
	if result then
		placeBuildable("stairs", "Building_stairs", result.Position)
	end
end)

iceArrowEvent.OnServerEvent:Connect(function(player)
	if canCast(player, "IceArrow") then
		spawnIceArrow(player.Character)
	end
end)

superEvent.OnServerEvent:Connect(function(player, position)
	if canCast(player, "Super") then
		spawnSuper(player, position)
	end
end)

npcArrowEvent.Event:Connect(function(character)
	spawnIceArrow(character)
end)

npcBallEvent.Event:Connect(function(character)
	spawnFireball(character)
end)

npcSpikesEvent.Event:Connect(function(character, root)
	if root then
		spawnSpikes(character, root.Position - Vector3.new(0, 4, 0))
	end
end)
