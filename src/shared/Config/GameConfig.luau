-- Central tuning values. Designers should be able to balance the game from here
-- without touching service code.

local GameConfig = {}

GameConfig.Version = "0.1.0"

-- Place ids are filled in after publishing (see docs/DEPLOYMENT.md).
-- 0 means "not published yet"; matchmaking then runs the chapter in the same server.
GameConfig.Places = {
	Lobby = 0,
	Chapter1 = 0,
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

GameConfig.Rewards = {
	ChapterCompleteEmbers = 150,
	ChapterCompleteXP = 400,
	FirstClearBonusEmbers = 250,
	SurvivedWithoutDownBonusXP = 150,
	VIPEmberMultiplier = 1.25,
}

return GameConfig
