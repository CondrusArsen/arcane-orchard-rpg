--!strict
--[[
	Behaviour for every enemy type. Archetype data (detection radius, attack
	list, reward) comes from shared/Config/Npc.

	Loop: patrol between points with PathfindingService; as soon as a living
	player is inside the detection radius, stop, face the closest one and use
	the first attack whose range fits the distance. Return to patrol when no
	target is left.
]]

local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NpcConfig = require(ReplicatedStorage.Shared.Config.Npc)
local Combat = require(script.Parent.Parent.Util.Combat)
local SpellEffects = require(script.Parent.Parent.Spells.SpellEffects)

type Target = {
	root: BasePart,
	distance: number,
}

local CAST_OFFSET = CFrame.new(0, 0, -5)
local ARRIVE_DISTANCE = 2.5
local MOVE_POLL_SECONDS = 0.1

local NpcBrain = {}

local function findTarget(origin: Vector3, radius: number): Target?
	local best: Target? = nil
	for _, player in Players:GetPlayers() do
		local character = player.Character
		if not character then
			continue
		end
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local root = character:FindFirstChild("HumanoidRootPart")
		if humanoid and humanoid.Health > 0 and root and root:IsA("BasePart") then
			local distance = (root.Position - origin).Magnitude
			if distance <= radius and (best == nil or distance < best.distance) then
				best = { root = root, distance = distance }
			end
		end
	end
	return best
end

local function loadWalkTrack(humanoid: Humanoid): AnimationTrack?
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		return nil
	end
	local animation = Instance.new("Animation")
	animation.AnimationId = NpcConfig.walkAnimationId
	local ok, track = pcall(function()
		return animator:LoadAnimation(animation)
	end)
	if not ok then
		warn(`[NpcBrain] Could not load walk animation: {track}`)
		return nil
	end
	track.Looped = true
	return track
end

function NpcBrain.run(rig: Model, archetype: NpcConfig.Archetype, patrolPoints: { BasePart })
	local humanoid = rig:FindFirstChildOfClass("Humanoid")
	local rootInstance = rig:FindFirstChild("HumanoidRootPart")
	if not humanoid or not (rootInstance and rootInstance:IsA("BasePart")) or #patrolPoints == 0 then
		warn(`[NpcBrain] {rig.Name} is missing a Humanoid, HumanoidRootPart or patrol points`)
		return
	end
	local root: BasePart = rootInstance

	local attacker: Combat.Attacker = { model = rig }
	local walkTrack = loadWalkTrack(humanoid)
	local nextAttackAt = 0
	humanoid.WalkSpeed = archetype.walkSpeed

	local function alive(): boolean
		return humanoid.Health > 0 and rig.Parent ~= nil
	end

	local function nearestTarget(): Target?
		return findTarget(root.Position, archetype.detectRadius)
	end

	-- Walks towards a point; returns false if interrupted by a target or death.
	local function moveTo(position: Vector3): boolean
		humanoid:MoveTo(position)
		local deadline = os.clock() + NpcConfig.waypointTimeout
		while os.clock() < deadline do
			if not alive() or nearestTarget() then
				return false
			end
			local offset = position - root.Position
			if Vector3.new(offset.X, 0, offset.Z).Magnitude <= ARRIVE_DISTANCE then
				return true
			end
			task.wait(MOVE_POLL_SECONDS)
		end
		return true
	end

	local function patrolTo(goal: BasePart)
		local path = PathfindingService:CreatePath(NpcConfig.pathAgent)
		local computed = pcall(function()
			path:ComputeAsync(root.Position, goal.Position)
		end)

		if walkTrack then
			walkTrack:Play()
		end
		if computed and path.Status == Enum.PathStatus.Success then
			for _, waypoint in path:GetWaypoints() do
				if waypoint.Action == Enum.PathWaypointAction.Jump then
					humanoid.Jump = true
				end
				if not moveTo(waypoint.Position) then
					break
				end
			end
		else
			-- No path (blocked or service error): try a straight line instead of freezing.
			moveTo(goal.Position)
		end
		if walkTrack then
			walkTrack:Stop()
		end
	end

	local function attack(target: Target)
		local now = os.clock()
		if now < nextAttackAt then
			return
		end
		for _, option in archetype.attacks do
			if target.distance >= option.minRange and target.distance <= option.maxRange then
				nextAttackAt = now + option.recovery
				if option.spell == "IceArrow" then
					SpellEffects.iceArrow(attacker, root.CFrame * CAST_OFFSET)
				elseif option.spell == "FireBall" then
					SpellEffects.fireball(attacker, root.CFrame * CAST_OFFSET)
				elseif option.spell == "Spikes" then
					local ground = SpellEffects.groundBelow(target.root.Position)
					if ground then
						SpellEffects.spikes(attacker, ground)
					end
				end
				return
			end
		end
	end

	local function engage()
		humanoid:MoveTo(root.Position)
		humanoid.WalkSpeed = 0

		while alive() do
			local target = nearestTarget()
			if not target then
				break
			end
			local flat = Vector3.new(target.root.Position.X, root.Position.Y, target.root.Position.Z)
			if (flat - root.Position).Magnitude > 0.1 then
				root.CFrame = CFrame.lookAt(root.Position, flat)
			end
			attack(target)
			task.wait(NpcConfig.thinkInterval)
		end

		if alive() then
			humanoid.WalkSpeed = archetype.walkSpeed
		end
	end

	task.spawn(function()
		local index = 1
		while alive() do
			if nearestTarget() then
				engage()
			else
				patrolTo(patrolPoints[index])
				index = index % #patrolPoints + 1
				task.wait(NpcConfig.patrolPause)
			end
		end
	end)
end

return NpcBrain
