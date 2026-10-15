-- Creature tuning. The Watcher hunts in Chapter 1, The Ranger in Chapter 2 and
-- The Mimic (voices, then a walking copy of a player) in Chapter 3. The Hollow
-- One is defined for Chapter 4 (docs/ROADMAP.md).

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
		height = 8,
		patrolSpeed = 8,
		investigateSpeed = 13,
		chaseSpeed = 16, -- sprinting (20) still gets away, walking (12) does not
		sightRange = 22, -- sees players this close in front of it
		litSightRange = 42, -- ...or this far if their light is on
		sightAngle = 55, -- degrees either side of its facing
		hearingMultiplier = 1,
		loseDistance = 42,
		searchTime = 6,
		catchDistance = 5,
		pauseAfterCatch = 4,
		elevatedHeight = 14, -- it will not climb after players higher than this
	},
	-- The Mimic's walking form (Chapter 3): a copy of one of the players.
	Copy = {
		activeFromChapter = 3,
		stalkSpeed = 11, -- a walking player (12) can keep away from it
		huntSpeed = 16,
		catchDistance = 4.5,
		followDistance = 14, -- how close it creeps to a group it can't catch
		lingerTime = 45, -- seconds it stays out before slipping away
		respawnDelay = { 18, 32 },
		revealCooldown = 30, -- seconds away after a handshake exposes it
		appearDistance = { 35, 75 },
		pauseAfterCatch = 4,
		revealStun = 4, -- in the finale a handshake only stuns it
	},
	-- The heart of the forest (Chapter 4). It never moves; its gaze sweeps the
	-- clearing like a lighthouse beam. Stone cover blocks it.
	HollowOne = {
		name = "The Hollow One",
		activeFromChapter = 4,
		gazeRange = 125, -- studs from its eye
		gazeHalfAngle = 16, -- degrees either side of where it is looking
		sweepSpeed = 22, -- degrees per second
		angrySweepSpeed = 40, -- after the braziers are lit
		exposureToCatch = 1.6, -- seconds in the beam before it pulls you down
		exposureFall = 1.5, -- exposure lost per second out of the beam
		fearPerSecond = 22,
	},
}
