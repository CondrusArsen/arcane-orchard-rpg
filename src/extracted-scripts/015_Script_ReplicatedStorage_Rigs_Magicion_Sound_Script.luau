local Humanoid = script.Parent.Parent:FindFirstChild("Humanoid")
local sonido = script.Parent

Humanoid.Died:Connect(function()
	
	sonido:Play()
	wait(5)
	script.Disabled = true
	wait(0,5)
	script.Disabled = false
	
end)