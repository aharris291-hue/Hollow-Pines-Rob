-- Creature tuning. Chapter 1 uses The Watcher fully and teases The Mimic.
-- The Ranger and The Hollow One are defined for later chapters (docs/ROADMAP.md).

return {
	Watcher = {
		name = "The Watcher",
		height = 11,
		lookAngle = 22, -- degrees from a player's facing that counts as "looking at it"
		lookRange = 140,
		relocateInterval = { 14, 26 }, -- seconds between silent repositions while stalking
		approachStep = 18, -- studs it closes in each time nobody is looking
		minStalkDistance = 35,
		maxStalkDistance = 110,
		vanishAfterSeen = 2.5, -- seconds of eye contact before it slips away
		chaseSpeed = 17, -- slower than sprint, faster than walk
		catchDistance = 5,
		fearAura = 1.0,
	},
	Mimic = {
		name = "The Mimic",
		voiceLines = {
			"{name}? Over here! I found a way out!",
			"Guys... wait for me...",
			"{name}, it's me. Come into the trees.",
			"Don't go to the station. Follow my voice.",
		},
		voiceInterval = { 45, 80 },
		decoyDistance = { 50, 90 }, -- the fake teammate stands this far away
		decoyVanishDistance = 25,
		fearSpike = 15,
	},
	Ranger = {
		name = "The Ranger",
		activeFromChapter = 2,
		patrolSpeed = 10,
		hearingRadius = 40,
	},
	HollowOne = {
		name = "The Hollow One",
		activeFromChapter = 4,
	},
}
