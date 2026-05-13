local cost = script.Parent
local each = cost.Parent:WaitForChild("TextLabel1")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local events = ReplicatedStorage:WaitForChild("Events")
local buyEvent = events:WaitForChild("AppleBuyEv")
local sellEvent = events:WaitForChild("AppleSellEv")
local appleTemplate = ReplicatedStorage:WaitForChild("Apple")

local function updatePrice()
	local costValue = math.random(25, 75)
	cost.Value = costValue
	each.Text = costValue .. "$ each"
end

updatePrice()
task.spawn(function()
	while script.Parent do
		task.wait(30)
		updatePrice()
	end
end)

buyEvent.OnServerEvent:Connect(function(player)
	local money = player:FindFirstChild("money")
	if not money or money.Value < cost.Value then
		return
	end

	money.Value -= cost.Value
	local clone = appleTemplate:Clone()
	clone.Parent = player:WaitForChild("Backpack")
end)

sellEvent.OnServerEvent:Connect(function(player)
	local backpack = player:FindFirstChild("Backpack")
	local apple = backpack and backpack:FindFirstChild("Apple")
	if not apple then
		return
	end

	local money = player:FindFirstChild("money")
	if money then
		money.Value += cost.Value
	end
	apple:Destroy()
end)
