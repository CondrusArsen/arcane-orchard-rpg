--!strict
-- Touch pads in Workspace.World.Boosters. Each folder holds any number of pads.

export type Booster = {
	folder: string,
	property: "WalkSpeed" | "JumpHeight",
	value: number,
	duration: number,
}

local boosters: { Booster } = {
	{ folder = "SpeedBoosters", property = "WalkSpeed", value = 40, duration = 8 },
	{ folder = "Jump_Boosters", property = "JumpHeight", value = 40, duration = 10 },
}

return boosters
