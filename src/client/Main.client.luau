--!strict
-- Client entry point. Controllers only render state and send requests.

local Controllers = script.Parent.Controllers

local Hud = require(Controllers.Hud)
local ShopController = require(Controllers.ShopController)
local SpellInput = require(Controllers.SpellInput)

Hud.start()
ShopController.start()
SpellInput.start()
