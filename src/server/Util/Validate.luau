--!strict
-- Type guards for values that arrive from the network.

local Validate = {}

local MAX_COORDINATE = 1e5

local function isFiniteNumber(value: number): boolean
	-- NaN is the only value not equal to itself.
	return value == value and math.abs(value) <= MAX_COORDINATE
end

function Validate.vector3(value: unknown): Vector3?
	if typeof(value) ~= "Vector3" then
		return nil
	end
	local vector = value :: Vector3
	if isFiniteNumber(vector.X) and isFiniteNumber(vector.Y) and isFiniteNumber(vector.Z) then
		return vector
	end
	return nil
end

-- Returns the character's root part when the player is alive and spawned.
function Validate.aliveRoot(player: Player): (Model?, BasePart?)
	local character = player.Character
	if not character then
		return nil, nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health <= 0 or not root or not root:IsA("BasePart") then
		return nil, nil
	end
	return character, root
end

return Validate
