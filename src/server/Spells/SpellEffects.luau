--!strict
--[[
	What each spell does once it has been allowed to happen.

	Used by SpellService (player casts, already validated and paid for) and by
	NpcBrain (enemy attacks). Projectiles are advanced by a single Heartbeat
	stepper and use raycasts between frames, so fast spells cannot tunnel
	through targets the way Touched-based projectiles do.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Spells = require(ReplicatedStorage.Shared.Config.Spells)
local Combat = require(script.Parent.Parent.Util.Combat)
local Prefabs = require(script.Parent.Parent.Util.Prefabs)

type Attacker = Combat.Attacker
-- Advances an effect by `dt`; returns false once the effect is finished.
type Stepper = (dt: number) -> boolean

local SPIKES_CHECK_INTERVAL = 0.2

local active: { Stepper } = {}
local frozenUntil: { [BasePart]: number } = {}
local random = Random.new()

local SpellEffects = {}

local function addStepper(stepper: Stepper)
	table.insert(active, stepper)
end

local function stepAll(dt: number)
	local index = 1
	while index <= #active do
		local ok, keep = pcall(active[index], dt)
		if not ok then
			warn(`[SpellEffects] Effect step failed: {keep}`)
		end
		if ok and keep then
			index += 1
		else
			-- Swap-remove: order does not matter and this avoids shifting the array.
			active[index] = active[#active]
			active[#active] = nil
		end
	end
end

local function effectsFolder(): Folder
	return Prefabs.workspaceFolder(Prefabs.Folders.Effects)
end

local function blastVisual(position: Vector3, radius: number)
	local explosion = Instance.new("Explosion")
	explosion.Position = position
	explosion.BlastRadius = radius
	-- Damage is applied by Combat; the explosion is only a visual and must not move the map.
	explosion.BlastPressure = 0
	explosion.DestroyJointRadiusPercent = 0
	explosion.Parent = effectsFolder()
end

local function freeze(root: BasePart, seconds: number)
	local untilTime = os.clock() + seconds
	frozenUntil[root] = math.max(frozenUntil[root] or 0, untilTime)
	root.Anchored = true

	task.delay(seconds, function()
		local current = frozenUntil[root]
		-- A later hit may have extended the freeze; only the last timer thaws.
		if current and os.clock() >= current then
			frozenUntil[root] = nil
			if root.Parent then
				root.Anchored = false
			end
		end
	end)
end

local function projectileParams(attacker: Attacker, projectile: Model): RaycastParams
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { attacker.model, projectile, effectsFolder() }
	return params
end

-- Ground position under `position`, ignoring characters, enemies and spell effects.
function SpellEffects.groundBelow(position: Vector3): Vector3?
	local ignore: { Instance } = { effectsFolder(), Prefabs.workspaceFolder(Prefabs.Folders.Enemies) }
	for _, player in Players:GetPlayers() do
		if player.Character then
			table.insert(ignore, player.Character)
		end
	end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignore

	local result = workspace:Raycast(position + Vector3.new(0, 50, 0), Vector3.new(0, -200, 0), params)
	return if result then result.Position else nil
end

function SpellEffects.fireball(attacker: Attacker, origin: CFrame)
	local model = Prefabs.cloneSpellVisual("FireBall_Prefab")
	local ball = model and model:FindFirstChild("FireBall")
	if not model or not (ball and ball:IsA("BasePart")) then
		if model then
			model:Destroy()
		end
		return
	end
	model:PivotTo(origin)
	model.Parent = effectsFolder()

	local tuning = Spells.FireBall
	local params = projectileParams(attacker, model)
	local verticalSpeed = tuning.launchLift
	local age = 0

	local function explode(position: Vector3)
		blastVisual(position, tuning.blastRadius)
		Combat.damageInRadius(attacker, position, tuning.blastRadius, tuning.damage)
		model:Destroy()
	end

	addStepper(function(dt)
		if not model.Parent then
			return false
		end

		age += dt
		verticalSpeed -= tuning.gravity * dt
		-- Motion is in the ball's own frame: forward along -Z with a gravity arc.
		local current = ball.CFrame
		local displacement = (current * CFrame.new(0, verticalSpeed * dt, -tuning.speed * dt)).Position
			- current.Position

		local hit = workspace:Raycast(current.Position, displacement, params)
		if hit then
			explode(hit.Position)
			return false
		end
		if age >= tuning.lifetime then
			explode(current.Position + displacement)
			return false
		end

		model:PivotTo(model:GetPivot() + displacement)
		return true
	end)
end

function SpellEffects.iceArrow(attacker: Attacker, origin: CFrame)
	local model = Prefabs.cloneSpellVisual("IceArrowPrefab")
	local arrow = model and model:FindFirstChild("Arrow")
	if not model or not (arrow and arrow:IsA("BasePart")) then
		if model then
			model:Destroy()
		end
		return
	end
	model:PivotTo(origin)
	model.Parent = effectsFolder()

	local tuning = Spells.IceArrow
	local params = projectileParams(attacker, model)
	local age = 0

	addStepper(function(dt)
		if not model.Parent then
			return false
		end

		age += dt
		-- The arrow mesh is modelled pointing along -Y.
		local displacement = -arrow.CFrame.UpVector * tuning.speed * dt
		local hit = workspace:Raycast(arrow.Position, displacement, params)
		if hit then
			local victim, humanoid = Combat.humanoidOf(hit.Instance)
			if victim and humanoid and Combat.damage(attacker, victim, humanoid, tuning.damage) then
				local root = victim:FindFirstChild("HumanoidRootPart")
				if root and root:IsA("BasePart") then
					freeze(root, tuning.freezeSeconds)
				end
			end
			model:Destroy()
			return false
		end
		if age >= tuning.lifetime then
			model:Destroy()
			return false
		end

		model:PivotTo(model:GetPivot() + displacement)
		return true
	end)
end

function SpellEffects.spikes(attacker: Attacker, groundPosition: Vector3)
	local model = Prefabs.cloneSpellVisual("Spikes_Prefab")
	local spikes = model and model:FindFirstChild("Spikes")
	if not model or not (spikes and spikes:IsA("BasePart")) then
		if model then
			model:Destroy()
		end
		return
	end
	model:PivotTo(CFrame.new(groundPosition + Vector3.new(0, 1, 0)))
	model.Parent = effectsFolder()

	local tuning = Spells.Spikes
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { attacker.model, model }

	local lastHit: { [Humanoid]: number } = {}
	local age = 0
	local sinceCheck = SPIKES_CHECK_INTERVAL

	addStepper(function(dt)
		if not model.Parent then
			return false
		end
		age += dt
		if age >= tuning.lifetime then
			model:Destroy()
			return false
		end

		sinceCheck += dt
		if sinceCheck < SPIKES_CHECK_INTERVAL then
			return true
		end
		sinceCheck = 0

		local now = os.clock()
		for _, part in workspace:GetPartBoundsInBox(spikes.CFrame, spikes.Size, params) do
			local victim, humanoid = Combat.humanoidOf(part)
			if victim and humanoid then
				local previous = lastHit[humanoid]
				if not previous or now - previous >= tuning.hitCooldown then
					if Combat.damage(attacker, victim, humanoid, tuning.damage) then
						lastHit[humanoid] = now
					end
				end
			end
		end
		return true
	end)
end

function SpellEffects.super(attacker: Attacker, target: Vector3)
	local tuning = Spells.Super

	for _ = 1, tuning.meteorCount do
		task.delay(random:NextNumber() * tuning.burstSeconds, function()
			if not attacker.model.Parent then
				return
			end
			local meteor = Prefabs.cloneSpellVisual("SuperMagicMeteor")
			if not meteor then
				return
			end

			local offset = Vector3.new(
				random:NextNumber(-tuning.spread, tuning.spread),
				0,
				random:NextNumber(-tuning.spread, tuning.spread)
			)
			local impact = target + offset
			meteor:PivotTo(CFrame.new(impact + Vector3.new(0, tuning.dropHeight, 0)))
			meteor.Parent = effectsFolder()

			local visual = meteor:FindFirstChildWhichIsA("BasePart", true)
			if visual then
				TweenService:Create(
					visual,
					TweenInfo.new(tuning.fallSeconds, Enum.EasingStyle.Linear),
					{ CFrame = CFrame.new(impact) }
				):Play()
			end

			task.delay(tuning.fallSeconds, function()
				meteor:Destroy()
				blastVisual(impact, tuning.blastRadius)
				Combat.damageInRadius(attacker, impact, tuning.blastRadius, tuning.damage)
			end)
		end)
	end
end

function SpellEffects.start()
	RunService.Heartbeat:Connect(stepAll)
end

return SpellEffects
