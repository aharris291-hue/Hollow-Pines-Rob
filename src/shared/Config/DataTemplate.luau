-- The shape of every saved profile. New keys added here are filled into old
-- profiles automatically on load (TableUtil.reconcile), so add, never rename.

return {
	SchemaVersion = 1,
	Embers = 0,
	XP = 0,
	Level = 1,
	Owned = {
		Flashlight = true,
		Walkie = true,
		FlashlightBeamWarm = true,
	},
	Loadout = {
		Light = "Flashlight",
		Tool = "Walkie",
	},
	EquippedPet = "",
	EquippedBeam = "FlashlightBeamWarm",
	EquippedTitle = "",
	Stats = {
		ChaptersStarted = 0,
		ChaptersCompleted = 0,
		FlawlessClears = 0,
		FusesInserted = 0,
		Revives = 0,
		WatcherSpotted = 0,
		NotesRead = 0,
		TimesCaught = 0,
		Chapter2Clears = 0,
		MapPiecesFound = 0,
		HidFromRanger = 0,
		FlaresFired = 0,
		Chapter3Clears = 0,
		MimicsRevealed = 0,
		Handshakes = 0,
		TapesFound = 0,
		Chapter4Clears = 0,
		LostFreed = 0,
		BraziersLit = 0,
		Level = 1,
	},
	Achievements = {},
	Quests = {
		Day = 0,
		Active = {}, -- { [questId] = { progress = number, claimed = boolean } }
	},
	Settings = {
		ReducedFlashing = false,
		ReducedShake = false,
		Captions = true,
		CalmerScares = false,
		ColorblindMarkers = false,
		TextScale = 1,
		MusicVolume = 0.6,
		EffectsVolume = 0.8,
	},
	Purchases = {}, -- receipt ids already granted, keeps ProcessReceipt idempotent
	PurchaseOrder = {}, -- receipt ids in grant order, used to trim Purchases
	FirstClear = false, -- Chapter 1 cleared (kept for old saves; see Cleared)
	Cleared = {}, -- { ["1"] = true, ["2"] = true } chapters finished at least once
	SecondWinds = 0, -- bought Second Wind revives not yet used
	SupporterGranted = false,
	HintsSeen = {}, -- first-time hints already shown: { [hintId] = true }
}
