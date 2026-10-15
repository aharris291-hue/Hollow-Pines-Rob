-- Achievements unlock once, from lifetime stats kept in the player's profile.
-- `stat` is a key in profile.Stats; `badgeId` is optional (0 = no Roblox badge yet).

return {
	{ id = "FirstSteps", name = "First Steps", text = "Wake up after the crash.", stat = "ChaptersStarted", goal = 1, embers = 25, badgeId = 0 },
	{ id = "SurviveTheStorm", name = "Survive the Storm", text = "Complete Chapter 1.", stat = "ChaptersCompleted", goal = 1, embers = 200, badgeId = 0, reward = "TitleSurvivor" },
	{ id = "Electrician", name = "Electrician", text = "Insert 25 fuses.", stat = "FusesInserted", goal = 25, embers = 100, badgeId = 0 },
	{ id = "GoodFriend", name = "Good Friend", text = "Revive 10 teammates.", stat = "Revives", goal = 10, embers = 150, badgeId = 0 },
	{ id = "Unblinking", name = "Unblinking", text = "Spot The Watcher 20 times.", stat = "WatcherSpotted", goal = 20, embers = 150, badgeId = 0 },
	{ id = "Untouchable", name = "Untouchable", text = "Complete Chapter 1 without being caught.", stat = "FlawlessClears", goal = 1, embers = 300, badgeId = 0 },
	{ id = "Archivist", name = "Archivist", text = "Read 30 notes.", stat = "NotesRead", goal = 30, embers = 120, badgeId = 0 },
	{ id = "Level10", name = "Night Owl", text = "Reach level 10.", stat = "Level", goal = 10, embers = 250, badgeId = 0, reward = "TitleNightOwl" },
}
