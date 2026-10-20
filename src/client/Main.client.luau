--!strict
-- Client entry point. Controllers only render state and send requests.

-- PlayerScripts replicate child by child, so wait for the modules before requiring them.
local Controllers = script.Parent:WaitForChild("Controllers")

local Hud = require(Controllers:WaitForChild("Hud"))
local ShopController = require(Controllers:WaitForChild("ShopController"))
local SpellInput = require(Controllers:WaitForChild("SpellInput"))

Hud.start()
ShopController.start()
SpellInput.start()
