-- Central tuning values. Designers should be able to balance the game from here
-- without touching service code.

local GameConfig = {}

GameConfig.Version = "0.1.0"

-- Place ids are filled in after publishing (see docs/DEPLOYMENT.md).
-- Optional: 0 means one-place mode, where the lobby place also runs every chapter
-- in reserved servers (docs/DEPLOYMENT.md).
GameConfig.Places = {
	Lobby = 0,
	Chapter1 = 0,
	Chapter2 = 0,
	Chapter3 = 0,
	Chapter4 = 0,
}

-- Fastest-escape leaderboards on the lobby board (one OrderedDataStore per chapter).
GameConfig.Leaderboards = {
	StoreName = "HollowPines_BestTimes_v1_Chapter", -- chapter id is appended
	Size = 10, -- names shown per chapter
	RefreshInterval = 90, -- seconds between lobby board refreshes
	PageSeconds = 8, -- how long the board shows each chapter
}

GameConfig.Party = {
	MinPlayers = 1,
	MaxPlayers = 6,
	QueueCountdown = 15, -- seconds after the first player joins a queue pad
	FullQueueCountdown = 5, -- seconds once the queue is full
}

GameConfig.Data = {
	StoreName = "HollowPines_PlayerData_v1",
	AutosaveInterval = 120,
	SessionLockTimeout = 1800, -- a lock older than this is treated as abandoned
	MaxRetries = 5,
}

GameConfig.Fear = {
	Max = 100,
	-- per-second changes
	DarknessGain = 1.2, -- standing without a light source
	AloneGain = 1.5, -- no teammate within AloneRadius
	CreatureNearGain = 6, -- scaled by distance inside CreatureRadius
	LightRecover = 1.0,
	TeammateRecover = 1.5,
	SafeZoneRecover = 6,
	AloneRadius = 30,
	CreatureRadius = 60,
	-- thresholds that change gameplay and presentation
	Uneasy = 35,
	Scared = 65,
	Panicked = 90,
	PanicWalkSpeedMultiplier = 0.85,
	CalmModeMultiplier = 0.5, -- accessibility "Calmer Scares" setting
}

GameConfig.Movement = {
	WalkSpeed = 12,
	SprintSpeed = 20,
	StaminaMax = 100,
	StaminaDrain = 18,
	StaminaRegen = 12,
}

GameConfig.Downed = {
	ReviveTime = 3, -- seconds a teammate must hold the prompt
	BleedOutTime = 25, -- seconds before a downed player respawns at the checkpoint
	RespawnFear = 50,
}

GameConfig.Chapter1 = {
	IntroLength = 12,
	FuseCount = 3,
	ChaseTimeLimit = 120,
	EndingPhotoHold = 8,
	ReturnToLobbyDelay = 25,
}

GameConfig.Chapter3 = {
	IntroLength = 10,
	TapeCount = 3,
	FerryDelay = 20, -- seconds after the signal until the ferry reaches the dock
	EndingPhotoHold = 8,
	ReturnToLobbyDelay = 25,
}

GameConfig.Chapter4 = {
	IntroLength = 10,
	LostCount = 3, -- the driver, the ranger and the pilot
	EndingPhotoHold = 10,
	CreditsLength = 45, -- the credits roll after the photo (Config/Credits); players can skip
	ReturnToLobbyDelay = 75, -- long enough to watch the credits, then the results
}

-- The secret handshake (Chapter 3): how players prove they are real.
GameConfig.Trust = {
	Range = 12, -- studs: who you can offer a handshake to
	Window = 4, -- seconds both players have to do it for it to count
	Cooldown = 1.5,
	AloneRadius = 26, -- a player with no teammate this close is "alone"
	TrustedCalm = 12, -- fear removed when a handshake is returned
}

GameConfig.Chapter2 = {
	IntroLength = 10,
	MapPieceCount = 4,
	HelicopterDelay = 45, -- seconds after the flare until the landing zone opens
	EndingPhotoHold = 8,
	ReturnToLobbyDelay = 25,
}

-- How far each kind of noise carries (studs). The Ranger hears anything within range.
GameConfig.Noise = {
	Sprint = 40,
	Splash = 26, -- moving through flood water, even walking
	SplashSprint = 55,
	Walkie = 60,
	Whistle = 90,
	Flare = 2000,
	MemorySeconds = 4, -- how long a noise stays interesting
}

GameConfig.Rewards = {
	ChapterCompleteEmbers = 150,
	ChapterCompleteXP = 400,
	FirstClearBonusEmbers = 250,
	SurvivedWithoutDownBonusXP = 150,
	VIPEmberMultiplier = 1.25,
}

return GameConfig
