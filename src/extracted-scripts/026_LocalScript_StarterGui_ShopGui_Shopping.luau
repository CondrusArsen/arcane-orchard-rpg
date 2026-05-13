local player = game.Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local gui = script.Parent
local frame = gui:WaitForChild("ShopFrame")
local sellButton = frame:WaitForChild("ApplesFrame"):WaitForChild("SellButton")
local openButton = gui:WaitForChild("OpenButton")

local moneyGui = player.PlayerGui:WaitForChild("MoneyGui"):WaitForChild("MoneyGenFrame")
local manaGui = player.PlayerGui:WaitForChild("ManaGui"):WaitForChild("ManaGenFrame")
local skillGui = player.PlayerGui:WaitForChild("SkillGui")

local events = ReplicatedStorage:WaitForChild("Events")
local buyEvent = events:WaitForChild("BuyEvent")
local moneyGenEvent = events:WaitForChild("MoneyGenEvent")
local manaGenEvent = events:WaitForChild("ManaGenEvent")
local appleBuyEvent = events:WaitForChild("AppleBuyEv")
local appleSellEvent = events:WaitForChild("AppleSellEv")

local moneyGeneratorStarted = false
local manaGeneratorStarted = false

local moneyLevel = moneyGui.TextLabel:WaitForChild("lvl")
local moneyDivision = moneyGui.TextLabel2:WaitForChild("Division")
local moneyCost = frame:WaitForChild("MoneyGenFrame"):WaitForChild("Cost")

local manaLevel = manaGui.TextLabel:WaitForChild("lvl")
local manaDivision = manaGui.TextLabel2:WaitForChild("Division")
local manaCost = frame:WaitForChild("ManaGenFrame"):WaitForChild("Cost")

local function canAfford(cost)
	local money = player:FindFirstChild("money")
	return money and money.Value >= cost
end

local function startMoneyGenerator()
	if moneyGeneratorStarted then
		return
	end
	moneyGeneratorStarted = true
	task.spawn(function()
		while moneyGeneratorStarted do
			moneyGenEvent:FireServer()
			task.wait(math.max(0.25, moneyDivision.Value))
		end
	end)
end

local function startManaGenerator()
	if manaGeneratorStarted then
		return
	end
	manaGeneratorStarted = true
	task.spawn(function()
		while manaGeneratorStarted do
			manaGenEvent:FireServer()
			task.wait(math.max(0.25, manaDivision.Value))
		end
	end)
end

local function setUnlocked(category, itemName)
	if category == "Skills" then
		local label = skillGui.Skills:FindFirstChild(itemName)
		if label then
			label.Visible = true
		end
	elseif category == "Buildings" then
		local label = skillGui.Buildings:FindFirstChild(itemName)
		if label then
			label.Visible = true
		end
	elseif category == "SuperFrame" then
		skillGui.SuperFrame.SuperiorLabel.Visible = true
	end
end

openButton.MouseButton1Click:Connect(function()
	frame.Visible = not frame.Visible
	openButton.Text = frame.Visible and "Close Market" or "Open Market"
end)

for _, itemFrame in ipairs(frame:GetChildren()) do
	if itemFrame:IsA("Frame") then
		local buyButton = itemFrame:FindFirstChild("BuyButton")
		local costValue = itemFrame:FindFirstChild("Cost")
		local category = itemFrame:FindFirstChild("Cat")
		if buyButton and costValue and category then
			buyButton.MouseButton1Click:Connect(function()
				local cost = math.floor(tonumber(costValue.Value) or 0)
				if cost < 0 or not canAfford(cost) then
					return
				end

				if category.Value == "Apples" then
					appleBuyEvent:FireServer()
					return
				end

				if category.Value == "MoneyGenFrame" then
					moneyLevel.Value += 1
					moneyDivision.Value = math.max(0.25, moneyDivision.Value / 2)
					moneyCost.Value = math.floor(moneyCost.Value * 1.5)
					moneyCost.Parent.TextLabel.Text = "money generator cost " .. moneyCost.Value .. " $"
					moneyGui.TextLabel.Text = "Money gen lvl:" .. moneyLevel.Value
					moneyGui.TextLabel2.Text = "Earns 1$/" .. moneyDivision.Value .. "s"
					startMoneyGenerator()
				elseif category.Value == "ManaGenFrame" then
					manaLevel.Value += 1
					manaDivision.Value = math.max(0.25, manaDivision.Value / 2)
					manaCost.Value = math.floor(manaCost.Value * 1.5)
					manaCost.Parent.TextLabel.Text = "mana generator cost " .. manaCost.Value .. " $"
					manaGui.TextLabel.Text = "Mana gen lvl:" .. manaLevel.Value
					manaGui.TextLabel2.Text = "Earns 1 Mana/" .. manaDivision.Value .. "s"
					startManaGenerator()
				elseif category.Value == "SuperFrame" then
					setUnlocked("SuperFrame")
					itemFrame:Destroy()
				else
					local nameValue = itemFrame:FindFirstChild("Name")
					if nameValue then
						setUnlocked(category.Value, nameValue.Value)
					end
					itemFrame:Destroy()
				end

				buyEvent:FireServer(cost)
				if buyButton.Parent then
					buyButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
					buyButton.Text = "Upgrade"
					buyButton.TextScaled = true
				end
			end)
		end
	end
end

sellButton.MouseButton1Click:Connect(function()
	appleSellEvent:FireServer()
end)
