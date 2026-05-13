local sparks = script.Parent:WaitForChild("Sparks")
while wait() do
	sparks.Acceleration = Vector3.new(math.random(-10,10),math.random(-10,5),math.random(-10,10))
end