--!strict
-- Server entry point. Services are plain ModuleScripts started in dependency order.

local Services = script.Parent.Services
local SpellsFolder = script.Parent.Spells

local PlayerData = require(Services.PlayerData)
local ResourceService = require(Services.ResourceService)
local AppleMarket = require(Services.AppleMarket)
local ShopService = require(Services.ShopService)
local SpellEffects = require(SpellsFolder.SpellEffects)
local Buildables = require(SpellsFolder.Buildables)
local SpellService = require(Services.SpellService)
local NpcService = require(Services.NpcService)
local BoosterService = require(Services.BoosterService)

PlayerData.start()
ResourceService.start()
AppleMarket.start()
ShopService.start()
SpellEffects.start()
Buildables.start()
SpellService.start()
BoosterService.start()
NpcService.start()
