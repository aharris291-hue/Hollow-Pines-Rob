-- Daily quests: three are picked per UTC day from this pool (see Util/QuestLogic).
-- `event` names match the server EventBus events that advance them. `chapter`
-- (optional) keeps a quest out of the roll until the player can play that chapter.

return {
	DailyCount = 3,
	Pool = {
		{ id = "FindFuses", text = "Insert 5 fuses", event = "FuseInserted", goal = 5, embers = 60, xp = 80 },
		{ id = "Revive", text = "Revive 2 teammates", event = "TeammateRevived", goal = 2, embers = 80, xp = 100 },
		{ id = "ClearChapter", text = "Escape the forest", event = "ChapterCompleted", goal = 1, embers = 120, xp = 150 },
		{ id = "ReadNotes", text = "Read 6 notes", event = "NoteRead", goal = 6, embers = 50, xp = 60 },
		{ id = "StareDown", text = "Spot The Watcher 3 times", event = "WatcherSpotted", goal = 3, embers = 70, xp = 90 },
		{ id = "StayTogether", text = "Spend 3 minutes near teammates", event = "TimeWithTeam", goal = 180, embers = 60, xp = 70 },
		{ id = "Photos", text = "Flash The Watcher with a camera", event = "WatcherFlashed", goal = 1, embers = 90, xp = 110 },
		{ id = "MapPieces", text = "Find 4 torn map pieces", event = "MapPieceFound", chapter = 2, goal = 4, embers = 70, xp = 90 },
		{ id = "HideFromRanger", text = "Hide from The Ranger twice", event = "HidFromRanger", chapter = 2, goal = 2, embers = 80, xp = 100 },
		{ id = "ExposeMimic", text = "Expose The Mimic with a handshake", event = "MimicRevealed", chapter = 3, goal = 1, embers = 90, xp = 110 },
		{ id = "Handshakes", text = "Shake hands with teammates 3 times", event = "Handshake", chapter = 3, goal = 3, embers = 60, xp = 70 },
		{ id = "Pings", text = "Ping your team 5 times", event = "WalkiePing", goal = 5, embers = 40, xp = 50 },
	},
}
