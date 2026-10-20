--!strict
--[[
	Network surface of the game. The RemoteEvents are declared in
	default.project.json, so they exist before any script runs.

	Client -> server (all arguments are re-validated on the server):
	  CastSpell(spellId: string, target: Vector3?)
	  PurchaseItem(itemId: string)
	  SellApple()

	Server -> client:
	  Notify(message: string)

	State (money, mana, unlocks, generator levels) is not sent through
	remotes: the server writes it to Player attributes, which replicate.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local folder = ReplicatedStorage:WaitForChild("Remotes")

return {
	CastSpell = folder:WaitForChild("CastSpell") :: RemoteEvent,
	PurchaseItem = folder:WaitForChild("PurchaseItem") :: RemoteEvent,
	SellApple = folder:WaitForChild("SellApple") :: RemoteEvent,
	Notify = folder:WaitForChild("Notify") :: RemoteEvent,
}
