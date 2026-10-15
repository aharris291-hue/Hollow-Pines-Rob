-- Runs one chapter of the story, start to finish, then sends players home or
-- starts over. The story itself lives in src/server/Chapters/ChapterN.luau; this
-- service owns everything chapters share: waiting for the party, objectives,
-- captions, checkpoints, safe zones, code puzzles, the escape run and rewards.
--
-- A chapter module returns:
--   id, title, config            from Config/Chapters + GameConfig.ChapterN
--   buildMap() -> refs           builds the world, returns references
--   applyLighting()
--   spawns(refs) -> { CFrame }   where players start
--   run(story)                   the beats, returns once everyone has escaped
--   ending(story) -> payload     the PhotoEnding payload (text, scene)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)
local Assets = require(Shared.Config.Assets)
local Net = require(Shared.Util.Net)
local PuzzleCode = require(Shared.Util.PuzzleCode)
local RateLimit = require(Shared.Util.RateLimit)
local EventBus = require(script.Parent.Parent.EventBus)
local Builder = require(script.Parent.Parent.World.Builder)
local ChaptersFolder = script.Parent.Parent:WaitForChild("Chapters")

local ChapterService = {}

local services
local chapter -- the running chapter module
local refs
local state = {
	phase = "Waiting",
	checkpoint = nil :: CFrame?,
	objective = nil,
	safeZones = {},
	code = nil, -- { answer, onSolved }
	caught = {} :: { [Player]: boolean },
	participants = {} :: { [Player]: boolean },
	startedAt = 0,
}
local codeLimiter = RateLimit.new(1.5)

----------------------------------------------------------------------------
-- Story helpers, handed to chapter modules as `story`

local Story = {}

function Story.rootOf(player: Player): BasePart?
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

function Story.caption(text: string, speaker: string?)
	Net.Event("Caption"):FireAllClients(text, speaker or "Story")
end

function Story.setObjective(text: string, marker: Vector3?)
	state.objective = { text = text, marker = marker }
	Net.Event("ObjectiveUpdated"):FireAllClients(text, marker)
end

function Story.effect(name: string, payload)
	Net.Event("ScreenEffect"):FireAllClients(name, payload or {})
end

function Story.toastAll(text: string, kind: string?)
	Net.Event("Toast"):FireAllClients(text, kind or "Info")
end

function Story.waitUntil(predicate: () -> boolean, interval: number?)
	while not predicate() do
		task.wait(interval or 0.25)
	end
end

function Story.anyPlayerWithin(position: Vector3, radius: number): Player?
	for _, player in Players:GetPlayers() do
		local root = Story.rootOf(player)
		if root and (root.Position - position).Magnitude <= radius then
			return player
		end
	end
	return nil
end

function Story.insideRegion(position: Vector3, region): boolean
	local localPoint = region.cframe:PointToObjectSpace(position)
	local half = region.size / 2
	return math.abs(localPoint.X) <= half.X and math.abs(localPoint.Y) <= half.Y and math.abs(localPoint.Z) <= half.Z
end

function Story.openNote(player: Player, title: string, body: string)
	Net.Event("OpenPanel"):FireClient(player, "Note", { title = title, body = body })
	EventBus.Fire("NoteRead", player)
end

function Story.notePrompt(part: BasePart, title: string, body: string)
	local prompt = Builder.prompt(part, "Read", title)
	prompt.Triggered:Connect(function(player)
		Story.openNote(player, title, body)
	end)
	return prompt
end

-- Waits until any player triggers a prompt on `part`; returns who did.
function Story.waitForPrompt(part: BasePart, action: string, objectText: string, hold: number?): Player
	local prompt = Builder.prompt(part, action, objectText, hold)
	local who: Player? = nil
	prompt.Triggered:Connect(function(player)
		who = who or player
	end)
	Story.waitUntil(function()
		return who ~= nil
	end)
	prompt:Destroy()
	return who :: Player
end

function Story.setCheckpoint(cframe: CFrame)
	state.checkpoint = cframe
end

function Story.setPhase(phase: string)
	state.phase = phase
end

function Story.addSafeZone(region)
	table.insert(state.safeZones, region)
end

-- Arms a code puzzle. Players enter it through the dial panel opened by
-- Story.openCodePanel; onSolved runs once with whoever got it right.
function Story.expectCode(answer: string, onSolved: (Player) -> ())
	state.code = { answer = answer, onSolved = onSolved }
end

function Story.openCodePanel(player: Player, title: string, subtitle: string)
	if state.code then
		Net.Event("OpenPanel"):FireClient(player, "Radio", { digits = #state.code.answer, title = title, subtitle = subtitle })
	end
end

function Story.generateCode(digits: number)
	return PuzzleCode.generate(os.time() + #game.JobId * 7919 + math.random(1, 9999), digits)
end

function Story.participantNames(): { string }
	local names = {}
	for player in state.participants do
		table.insert(names, player.DisplayName)
	end
	return names
end

-- Title card + scripted intro on every client, then gameplay begins.
function Story.intro(payload)
	state.phase = "Intro"
	payload.names = Story.participantNames()
	payload.chapter = chapter.id
	payload.title = chapter.title
	Net.Event("Cutscene"):FireAllClients("Intro", payload)
	task.wait(payload.length)
	state.phase = "Playing"
	for player in state.participants do
		EventBus.Fire("ChapterStarted", player)
	end
end

function Story.escape(player: Player, hold: CFrame, message: string)
	if player:GetAttribute("Escaped") then
		return
	end
	player:SetAttribute("Escaped", true)
	player:SetAttribute("Hidden", nil)
	if services.PlayerStateService:IsDowned(player) then
		services.PlayerStateService:Revive(player, nil)
	end
	local character = player.Character
	if character then
		character:PivotTo(hold * CFrame.new(math.random(-6, 6), 0, math.random(-3, 3)))
	end
	Story.caption(string.format(message, player.DisplayName))
end

-- The finale: players run for `exitZone` while a creature hunts them.
-- opts = { exitZone, exitHold, escapedText, creature, restart: () -> (), speedUpAfter, onSpeedUp }
function Story.runEscape(opts)
	state.phase = "Chase"
	local chaseStart = os.clock()
	local firstEscape: number? = nil
	local spedUp = false
	local retreated = false

	while true do
		task.wait(0.25)
		local remaining, active = 0, 0
		for _, player in Players:GetPlayers() do
			if not player:GetAttribute("Escaped") then
				remaining += 1
				local root = Story.rootOf(player)
				if root and Story.insideRegion(root.Position, opts.exitZone) then
					Story.escape(player, opts.exitHold, opts.escapedText)
					firstEscape = firstEscape or os.clock()
				elseif not player:GetAttribute("Downed") then
					active += 1
				end
			end
		end

		if remaining == 0 then
			break
		end
		-- Stragglers are pulled along once someone has been safe for a while.
		if firstEscape and os.clock() - firstEscape > 45 then
			for _, player in Players:GetPlayers() do
				if not player:GetAttribute("Escaped") then
					Story.escape(player, opts.exitHold, opts.escapedText)
				end
			end
			break
		end
		if opts.speedUpAfter and not spedUp and os.clock() - chaseStart > opts.speedUpAfter then
			spedUp = true
			opts.creature:AddSpeed(3)
			Story.caption("It's getting faster. Hurry!")
		end
		-- Everyone still running is down: it backs off until they're back up.
		if active == 0 and not retreated then
			retreated = true
			opts.creature:SetMode("Hidden")
		elseif active > 0 and retreated then
			retreated = false
			task.wait(4)
			opts.restart()
		end
	end

	opts.creature:SetMode("Hidden")
	Story.effect("ChaseEnd", {})
end

----------------------------------------------------------------------------
-- Public API used by other services

function ChapterService:IsGameplayActive(): boolean
	return state.phase == "Playing" or state.phase == "Chase"
end

function ChapterService:IsInSafeZone(position: Vector3): boolean
	for _, region in state.safeZones do
		if region.active ~= false and Story.insideRegion(position, region) then
			return true
		end
	end
	return false
end

function ChapterService:GetCheckpoint(): CFrame?
	return state.checkpoint
end

function ChapterService:GetChapterId(): number
	return chapter and chapter.id or 1
end

function ChapterService:GetRefs()
	return refs
end

----------------------------------------------------------------------------
-- Run loop

local function resolveChapter()
	local role = ReplicatedStorage:GetAttribute("PlaceRole")
	local id = 1
	if role == "Chapter2" then
		id = 2
	elseif role == "Solo" then
		id = ReplicatedStorage:GetAttribute("SoloChapter") or 1
	end
	local module = ChaptersFolder:FindFirstChild("Chapter" .. id) or ChaptersFolder.Chapter1
	return require(module)
end

local function resetRun()
	if refs and refs.Map then
		refs.Map:Destroy()
	end
	services.CreatureService:Despawn()
	services.EquipmentService:ResetRun()
	services.PlayerStateService:ResetRun()
	services.FearService:ResetAll()
	if services.NoiseService then
		services.NoiseService:Clear()
	end
	state.phase = "Waiting"
	state.code = nil
	table.clear(state.safeZones)
	table.clear(state.caught)
	table.clear(state.participants)
	for _, player in Players:GetPlayers() do
		player:SetAttribute("Fuses", nil)
		player:SetAttribute("Hidden", nil)
	end

	refs = chapter.buildMap()
	services.CreatureService:Spawn(chapter.id)
	state.checkpoint = chapter.spawns(refs)[1]
end

local function expectedPartySize(): number
	for _, player in Players:GetPlayers() do
		local joinData = player:GetJoinData()
		local teleportData = joinData and joinData.TeleportData
		if type(teleportData) == "table" and type(teleportData.partySize) == "number" then
			return math.clamp(teleportData.partySize, 1, GameConfig.Party.MaxPlayers)
		end
	end
	return 1
end

local function waitForPlayers()
	Story.setObjective("Waiting for everyone to arrive...", nil)
	Story.waitUntil(function()
		for _, player in Players:GetPlayers() do
			if Story.rootOf(player) then
				return true
			end
		end
		return false
	end, 0.5)
	-- Give the rest of a teleported party a moment to arrive.
	local deadline = os.clock() + 20
	while #Players:GetPlayers() < expectedPartySize() and os.clock() < deadline do
		task.wait(0.5)
	end
	task.wait(2)
	local spawns = chapter.spawns(refs)
	for i, player in Players:GetPlayers() do
		state.participants[player] = true
		local character = player.Character
		if character then
			character:PivotTo(spawns[(i - 1) % #spawns + 1])
		end
	end
end

local function grantRewards()
	local key = tostring(chapter.id)
	local elapsed = math.floor(os.clock() - state.startedAt)
	for _, player in Players:GetPlayers() do
		if state.participants[player] then
			local flawless = not state.caught[player]
			local data = services.DataService:Get(player)
			local alreadyCleared = data and (data.Cleared[key] or (chapter.id == 1 and data.FirstClear))
			local firstClear = data ~= nil and not alreadyCleared
			local embers = services.EconomyService:Add(player, GameConfig.Rewards.ChapterCompleteEmbers, "Chapter" .. key .. "Complete", true)
			if firstClear then
				embers += services.EconomyService:Add(player, GameConfig.Rewards.FirstClearBonusEmbers, "Chapter" .. key .. "FirstClear", true)
			end
			services.DataService:Update(player, function(d)
				d.Cleared[key] = true
				if chapter.id == 1 then
					d.FirstClear = true
				end
			end)
			local xp = GameConfig.Rewards.ChapterCompleteXP + (if flawless then GameConfig.Rewards.SurvivedWithoutDownBonusXP else 0)
			services.ProgressionService:AddXP(player, xp)
			EventBus.Fire("ChapterCompleted", player)
			EventBus.Fire("Chapter" .. key .. "Completed", player)
			if flawless then
				EventBus.Fire("FlawlessClear", player)
			end
			Net.Event("ChapterResult"):FireClient(player, {
				chapter = chapter.id,
				title = chapter.title,
				embers = embers,
				xp = xp,
				flawless = flawless,
				firstClear = firstClear,
				seconds = elapsed,
				canReturn = GameConfig.Places.Lobby ~= 0,
				nextIn = chapter.config.ReturnToLobbyDelay,
			})
		end
	end
end

local function runEnding()
	state.phase = "Ending"
	Story.setObjective("", nil)
	local payload = chapter.ending(Story)
	local userIds = {}
	for _, player in Players:GetPlayers() do
		table.insert(userIds, player.UserId)
	end
	payload.userIds = userIds
	payload.hold = chapter.config.EndingPhotoHold
	Net.Event("PhotoEnding"):FireAllClients(payload)
	task.wait(payload.hold + 4)
	grantRewards()
	task.wait(chapter.config.ReturnToLobbyDelay)
end

local function runChapter()
	resetRun()
	waitForPlayers()
	state.startedAt = os.clock()
	services.OnboardingService:NewRun(chapter.id)
	chapter.run(Story)
	runEnding()
	services.OnboardingService:Step(10, "ChapterComplete")
end

local function sendAllHome()
	local lobby = GameConfig.Places.Lobby
	if lobby == 0 then
		return false
	end
	local ok, err = pcall(TeleportService.TeleportAsync, TeleportService, lobby, Players:GetPlayers())
	if not ok then
		warn("[ChapterService] return to lobby failed: " .. tostring(err))
	end
	return ok
end

----------------------------------------------------------------------------
-- Service lifecycle

function ChapterService:Init(registry)
	services = registry
	Story.services = registry
	setmetatable(Story, {
		__index = function(_, key)
			if key == "refs" then
				return refs
			elseif key == "chapter" then
				return chapter
			end
			return nil
		end,
	})

	chapter = resolveChapter()
	ReplicatedStorage:SetAttribute("Chapter", chapter.id)

	Net.Event("SubmitRadioCode").OnServerEvent:Connect(function(player, attempt)
		local code = state.code
		if not code or not codeLimiter:Allow(player) or type(attempt) ~= "string" or #attempt > 12 then
			return
		end
		if PuzzleCode.check(code.answer, attempt) then
			state.code = nil
			Net.Event("OpenPanel"):FireAllClients("Close", {})
			code.onSolved(player)
		else
			Net.Event("Toast"):FireClient(player, "That's not it.", "Warning")
			services.FearService:Spike(player, 4)
		end
	end)

	Net.Event("ReturnToLobby").OnServerEvent:Connect(function(player)
		local lobby = GameConfig.Places.Lobby
		if lobby ~= 0 and state.phase == "Ending" then
			pcall(TeleportService.TeleportAsync, TeleportService, lobby, { player })
		end
	end)

	services.PlayerStateService.Downed:Connect(function(player)
		state.caught[player] = true
	end)
end

function ChapterService:Start()
	chapter.applyLighting()
	task.spawn(function()
		while true do
			task.wait(math.random(25, 55))
			if chapter.thunder and state.phase ~= "Waiting" and state.phase ~= "Ending" then
				Story.effect("Thunder", { soundId = Assets.Sounds.Thunder })
			end
		end
	end)

	local function onCharacter(player: Player, character: Model)
		character:WaitForChild("HumanoidRootPart", 10)
		task.wait()
		if state.checkpoint then
			character:PivotTo(state.checkpoint * CFrame.new(math.random(-3, 3), 0, math.random(-3, 3)))
		end
		if services.EquipmentService:IsEnabled() then
			services.DataService:WaitFor(player)
			services.EquipmentService:GiveLoadout(player)
		end
	end
	local function hook(player: Player)
		player.CharacterAdded:Connect(function(character)
			onCharacter(player, character)
		end)
		if player.Character then
			task.spawn(onCharacter, player, player.Character)
		end
		-- Late joiners see the current objective and join the run.
		if state.objective then
			Net.Event("ObjectiveUpdated"):FireClient(player, state.objective.text, state.objective.marker)
		end
		if state.phase ~= "Waiting" then
			state.participants[player] = true
		end
	end
	Players.PlayerAdded:Connect(hook)
	for _, player in Players:GetPlayers() do
		hook(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		state.participants[player] = nil
		state.caught[player] = nil
	end)

	while true do
		local ok, err = pcall(runChapter)
		if not ok then
			warn("[ChapterService] chapter run failed: " .. tostring(err))
			task.wait(5)
		end
		if ok and sendAllHome() then
			task.wait(30) -- teleports in flight; restart if anyone stayed
		end
		while #Players:GetPlayers() == 0 do
			task.wait(1)
		end
	end
end

return ChapterService
