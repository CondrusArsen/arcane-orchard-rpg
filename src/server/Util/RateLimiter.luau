--!strict
--[[
	Per-player token bucket for RemoteEvent handlers.

	local allow = RateLimiter.new(5, 10) -- 5 requests/second, bursts of 10
	if not allow(player) then return end
]]

local Players = game:GetService("Players")

type Bucket = { tokens: number, updatedAt: number }

local RateLimiter = {}

function RateLimiter.new(ratePerSecond: number, burst: number): (player: Player) -> boolean
	local buckets: { [Player]: Bucket } = {}

	Players.PlayerRemoving:Connect(function(player)
		buckets[player] = nil
	end)

	return function(player: Player): boolean
		local now = os.clock()
		local bucket = buckets[player]
		if not bucket then
			bucket = { tokens = burst, updatedAt = now }
			buckets[player] = bucket
		end

		bucket.tokens = math.min(burst, bucket.tokens + (now - bucket.updatedAt) * ratePerSecond)
		bucket.updatedAt = now

		if bucket.tokens < 1 then
			return false
		end
		bucket.tokens -= 1
		return true
	end
end

return RateLimiter
