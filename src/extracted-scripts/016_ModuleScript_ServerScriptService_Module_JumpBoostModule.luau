local JumpSettings = {}
local JumpBoost = 40
local JumpNormal = 7.2
JumpSettings.BoostTime = 10

function JumpSettings.JumpBoostStart(char)	
	char.Humanoid.JumpHeight = JumpBoost	
end

function JumpSettings.JumpBoostEnd(char)
	char.Humanoid.JumpHeight = JumpNormal
end

return JumpSettings
