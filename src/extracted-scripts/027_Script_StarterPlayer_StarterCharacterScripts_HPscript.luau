local HPev = game:GetService("ReplicatedStorage").Events:WaitForChild("HPevent")

local char = script.Parent
local player = game:GetService("Players"):GetPlayerFromCharacter(char)
local hum = char:WaitForChild("Humanoid")

HPev:FireClient(player, hum.Health)
hum:GetPropertyChangedSignal("Health"):Connect(function()
	HPev:FireClient(player, hum.Health)
end)