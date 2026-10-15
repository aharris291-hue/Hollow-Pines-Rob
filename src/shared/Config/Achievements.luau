-- Achievements unlock once, from lifetime stats kept in the player's profile.
-- `stat` is a key in profile.Stats; `badgeId` is optional (0 = no Roblox badge yet).

return {
	{ id = "FirstSteps", name = "First Steps", text = "Wake up after the crash.", stat = "ChaptersStarted", goal = 1, embers = 25, badgeId = 0 },
	{ id = "SurviveTheStorm", name = "Survive the Storm", text = "Complete Chapter 1.", stat = "ChaptersCompleted", goal = 1, embers = 200, badgeId = 0, reward = "TitleSurvivor" },
	{ id = "Electrician", name = "Electrician", text = "Insert 25 fuses.", stat = "FusesInserted", goal = 25, embers = 100, badgeId = 0 },
	{ id = "GoodFriend", name = "Good Friend", text = "Revive 10 teammates.", stat = "Revives", goal = 10, embers = 150, badgeId = 0 },
	{ id = "Unblinking", name = "Unblinking", text = "Spot The Watcher 20 times.", stat = "WatcherSpotted", goal = 20, embers = 150, badgeId = 0 },
	{ id = "Untouchable", name = "Untouchable", text = "Complete a chapter without being caught.", stat = "FlawlessClears", goal = 1, embers = 300, badgeId = 0 },
	{ id = "Archivist", name = "Archivist", text = "Read 30 notes.", stat = "NotesRead", goal = 30, embers = 120, badgeId = 0 },
	{ id = "LightsOut", name = "Lights Out", text = "Complete Chapter 2.", stat = "Chapter2Clears", goal = 1, embers = 250, badgeId = 0 },
	{ id = "Cartographer", name = "Cartographer", text = "Find 20 torn map pieces.", stat = "MapPiecesFound", goal = 20, embers = 120, badgeId = 0 },
	{ id = "StillAsStone", name = "Still as Stone", text = "Hide from The Ranger 10 times.", stat = "HidFromRanger", goal = 10, embers = 150, badgeId = 0 },
	{ id = "SignalFire", name = "Signal Fire", text = "Fire the flare from the lookout tower.", stat = "FlaresFired", goal = 1, embers = 80, badgeId = 0 },
	{ id = "FogLifter", name = "Fog Lifter", text = "Complete Chapter 3.", stat = "Chapter3Clears", goal = 1, embers = 300, badgeId = 0 },
	{ id = "TrustNoOne", name = "Trust No One", text = "Expose The Mimic with a handshake 10 times.", stat = "MimicsRevealed", goal = 10, embers = 180, badgeId = 0 },
	{ id = "BestFriends", name = "Best Friends", text = "Complete 25 secret handshakes.", stat = "Handshakes", goal = 25, embers = 120, badgeId = 0 },
	{ id = "TheEnd", name = "Home Again", text = "Complete Chapter 4 and bring everyone home.", stat = "Chapter4Clears", goal = 1, embers = 500, badgeId = 0, reward = "TitleHomeAgain" },
	{ id = "Rescuer", name = "Rescuer", text = "Wake 10 lost adults.", stat = "LostFreed", goal = 10, embers = 150, badgeId = 0 },
	{ id = "Lightbringer", name = "Lightbringer", text = "Light 10 stone fires.", stat = "BraziersLit", goal = 10, embers = 150, badgeId = 0 },
	{ id = "Level10", name = "Night Owl", text = "Reach level 10.", stat = "Level", goal = 10, embers = 250, badgeId = 0, reward = "TitleNightOwl" },
}
