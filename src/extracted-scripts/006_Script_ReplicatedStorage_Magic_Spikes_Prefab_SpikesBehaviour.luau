local Debris = game:GetService("Debris")

local model = script.Parent
local spikes = model:WaitForChild("Spikes")
local damage = 30
local cooldown = 1.5
local lastHit = {}

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

spikes.Touched:Connect(function(hit)
	local character = hit.Parent
	local humanoid = character and character:FindFirstChild("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return
	end

	local now = os.clock()
	if lastHit[humanoid] and now - lastHit[humanoid] < cooldown then
		return
	end
	lastHit[humanoid] = now

	local owner = ownerPlayer()
	local victim = game.Players:GetPlayerFromCharacter(character)
	if owner and victim == owner then
		return
	end

	tagHumanoid(humanoid, owner)
	humanoid:TakeDamage(damage)
end)

Debris:AddItem(model, 6)
