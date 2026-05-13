local settings = {}

local norm = 16
local speed = 40
settings.boost_time = 8

function settings.speedup(hum)
	hum.WalkSpeed = speed
end

function settings.speeddown(hum)
	hum.WalkSpeed = norm
end

return settings