local shooted = false
local RS = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")

local DetectR = 210
local RotationTime = 0.05
local founded = false

local pathService = game:GetService("PathfindingService")
local path_params = {
	AgentRadius = 2.5,
	AgentHeight = 6.5,
	AgentCanJump = true
}	
local archer = script.Parent
local hum = archer:WaitForChild("Humanoid")
local hrp = archer:WaitForChild("HumanoidRootPart")
local part1 = archer:WaitForChild("PartTo").Value
local move_to_part = workspace.World.MovePartsFolder:WaitForChild(part1.Name)
local NPCball = RS.Events:WaitForChild("NPC_ball_Event")
local NPCarrow = RS.Events:WaitForChild("NPC_arrow_Event")
local NPCspikes = RS.Events:WaitForChild("NPC_spikes_Event")

local anim1 = "rbxassetid://180426354"
local wait_time = 1

local animator = hum:FindFirstChildOfClass("Animator")

local anim = Instance.new("Animation")
anim.AnimationId = anim1
local animTrack = animator:LoadAnimation(anim)
animTrack.Looped = true

local function getPlayerInRadius(radious)
	local foundedChar = nil
	local foundedPlr = nil
	local foundedDistance = radious
	for i, v in pairs(players:GetPlayers()) do
		local char = v.Character
		local HRP 
		local humanoid
		if char then
			HRP = char:FindFirstChild("HumanoidRootPart")
			humanoid = char:FindFirstChild("Humanoid")
		else
			return
		end
		if HRP and humanoid and humanoid.Health >= 1 then
			local distance = (HRP.Position - hrp.Position).magnitude
			if distance <= foundedDistance then
				foundedDistance = distance
				foundedChar = char
				foundedPlr = v
			end
		end
	end
	return foundedPlr, foundedChar, foundedDistance
end

local function shooting()
	if shooted == true then return end
	shooted = true
	task.spawn(function()
		while shooted do
			local plr, char, dis = getPlayerInRadius(DetectR)
			if not plr and not char and not dis then
				break
			end
			if dis <= 40 then
				NPCspikes:Fire(archer, char.HumanoidRootPart)
				task.wait(3)
			elseif dis > 190 then
			NPCball:Fire(archer)
				task.wait(6)
			elseif dis <= 190 and dis > 40 then
				NPCarrow:Fire(archer)
				task.wait(4)
			end
		end
	end)
end

local function vnimanie(targetedHRP)
	hum:MoveTo(hrp.Position)
	hum.WalkSpeed = 0
	local look_way = Vector3.new(targetedHRP.Position.X, hrp.Position.Y, targetedHRP.Position.Z)
	hrp.CFrame = CFrame.lookAt(hrp.Position, look_way)
end

local function dlitelnost()
	while true do
		local plr, char = getPlayerInRadius(DetectR)
		if not plr and not char then
			break
		end
		local targetHRP = char:FindFirstChild("HumanoidRootPart")
		if  not targetHRP then
			break
		end
		vnimanie(targetHRP)
		if founded == false then
			founded = true
--			fireball i babah
			shooting()
		end
		task.wait(RotationTime)
	end
	founded = false
	shooted = false
	hum.WalkSpeed = 16
end

local function patrulirovanie(part)
	local path = pathService:CreatePath()
	path:ComputeAsync(hrp.Position, part.Position)
	animTrack:Play()
	for i, v in pairs(path:GetWaypoints()) do
		local player = getPlayerInRadius(DetectR)
		if player then
			animTrack:Stop()
			dlitelnost()
			animTrack:Play()
		end
		if v.Action == Enum.PathWaypointAction.Jump then
			hum.Jump = true
		end
		hum:MoveTo(v.Position)
		hum.MoveToFinished:Wait()
	end
	animTrack:Stop()
end

while true do
	patrulirovanie(move_to_part)
	wait(wait_time)
	patrulirovanie(part1)
	wait(wait_time)
end