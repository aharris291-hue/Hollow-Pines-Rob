-- Chapter 1, "The Storm", start to finish. The story is a plain sequence of
-- beats in runChapter(), each waiting on something the players do.
--
--   crash -> empty driver's seat -> emergency kit -> footprints (first Watcher
--   sighting) -> ranger station -> 3 fuses -> radio code (Mimic teaser) ->
--   map table -> chase to the bridge -> the photograph

local Lighting = game:GetService("Lighting")
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
local Chapter1Map = require(script.Parent.Parent:WaitForChild("World"):WaitForChild("Chapter1Map"))
local Builder = require(script.Parent.Parent.World.Builder)

local ChapterService = {}

local CH = GameConfig.Chapter1
local DRIVER = "Mr. Dorsey"

local services
local refs
local state = {
	phase = "Waiting",
	checkpoint = nil :: CFrame?,
	objective = nil,
	power = false,
	radioCode = "",
	radioSolved = false,
	caught = {} :: { [Player]: boolean },
	participants = {} :: { [Player]: boolean },
	startedAt = 0,
}
local radioLimiter = RateLimit.new(1.5)

----------------------------------------------------------------------------
-- Helpers

local function rootOf(player: Player): BasePart?
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function caption(text: string, speaker: string?)
	Net.Event("Caption"):FireAllClients(text, speaker or "Story")
end

local function setObjective(text: string, marker: Vector3?)
	state.objective = { text = text, marker = marker }
	Net.Event("ObjectiveUpdated"):FireAllClients(text, marker)
end

local function effect(name: string, payload)
	Net.Event("ScreenEffect"):FireAllClients(name, payload or {})
end

local function waitUntil(predicate: () -> boolean, interval: number?)
	while not predicate() do
		task.wait(interval or 0.25)
	end
end

local function anyPlayerWithin(position: Vector3, radius: number): Player?
	for _, player in Players:GetPlayers() do
		local root = rootOf(player)
		if root and (root.Position - position).Magnitude <= radius then
			return player
		end
	end
	return nil
end

local function insideRegion(position: Vector3, region): boolean
	local localPoint = region.cframe:PointToObjectSpace(position)
	local half = region.size / 2
	return math.abs(localPoint.X) <= half.X and math.abs(localPoint.Y) <= half.Y and math.abs(localPoint.Z) <= half.Z
end

local function placeAtCheckpoint(player: Player)
	local root = rootOf(player)
	if root and state.checkpoint then
		player.Character:PivotTo(state.checkpoint * CFrame.new(math.random(-3, 3), 0, math.random(-3, 3)))
	end
end

local function openNote(player: Player, title: string, body: string)
	Net.Event("OpenPanel"):FireClient(player, "Note", { title = title, body = body })
	EventBus.Fire("NoteRead", player)
end

local function notePrompt(part: BasePart, title: string, body: string)
	local prompt = Builder.prompt(part, "Read", title)
	prompt.Triggered:Connect(function(player)
		openNote(player, title, body)
	end)
	return prompt
end

----------------------------------------------------------------------------
-- Atmosphere

local function applyStormLighting()
	Lighting.ClockTime = 0.2
	Lighting.Brightness = 0.6
	Lighting.Ambient = Color3.fromRGB(22, 24, 34)
	Lighting.OutdoorAmbient = Color3.fromRGB(34, 38, 52)
	Lighting.EnvironmentDiffuseScale = 0.2
	Lighting.EnvironmentSpecularScale = 0.2
	Lighting.GlobalShadows = true
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
	atmosphere.Density = 0.42
	atmosphere.Offset = 0.1
	atmosphere.Color = Color3.fromRGB(70, 80, 100)
	atmosphere.Decay = Color3.fromRGB(30, 32, 44)
	atmosphere.Glare = 0
	atmosphere.Haze = 2.2
	atmosphere.Parent = Lighting
	local grade = Lighting:FindFirstChild("StormGrade") or Instance.new("ColorCorrectionEffect")
	grade.Name = "StormGrade"
	grade.Saturation = -0.35
	grade.Contrast = 0.1
	grade.TintColor = Color3.fromRGB(215, 225, 255)
	grade.Parent = Lighting
end

local function thunderLoop()
	while true do
		task.wait(math.random(25, 55))
		if state.phase ~= "Waiting" and state.phase ~= "Ending" then
			effect("Thunder", { soundId = Assets.Sounds.Thunder })
		end
	end
end

----------------------------------------------------------------------------
-- Public API used by other services

function ChapterService:IsGameplayActive(): boolean
	return state.phase == "Playing" or state.phase == "Chase"
end

function ChapterService:IsInSafeZone(position: Vector3): boolean
	return state.power and refs ~= nil and insideRegion(position, refs.SafeZone)
end

function ChapterService:GetCheckpoint(): CFrame?
	return state.checkpoint
end

----------------------------------------------------------------------------
-- Story beats

local function beatIntro()
	state.phase = "Intro"
	local names = {}
	for player in state.participants do
		table.insert(names, player.DisplayName)
	end
	Net.Event("Cutscene"):FireAllClients("Intro", { length = CH.IntroLength, names = names, crashSound = Assets.Sounds.BusCrash })
	task.wait(CH.IntroLength)
	state.phase = "Playing"
	for player in state.participants do
		EventBus.Fire("ChapterStarted", player)
	end
end

local function beatDriver()
	setObjective("Check on the driver", refs.DriverSeat.Position)
	local checked = false
	local prompt = Builder.prompt(refs.DriverSeat, "Check", "Driver's seat")
	prompt.Triggered:Connect(function(player)
		openNote(player, "The driver's seat", DRIVER .. " is gone.\n\nThe seatbelt has been cut clean through. The bus door was forced open from the OUTSIDE.\n\nThere are muddy footprints leading into the trees.")
		if not checked then
			checked = true
			caption(player.DisplayName .. " checked the driver's seat. " .. DRIVER .. " is missing.")
		end
	end)
	notePrompt(refs.BusNote, "Field trip itinerary", "HOLLOW PINES MIDDLE SCHOOL - Nature Reserve Trip\n\n4:00 PM  Leave the reserve\n4:30 PM  Shortcut via the old forest road (bridge closed?)\n\nRemember: stay with your buddy at ALL times.\n\nSomeone has scribbled at the bottom: \"who is the extra kid in the back seat?\"")
	waitUntil(function()
		return checked
	end)
	prompt:Destroy()
end

local function beatKit()
	setObjective("Search the emergency kit at the back of the bus", refs.KitCrate.Position)
	local found = false
	local prompt = Builder.prompt(refs.KitCrate, "Search", "Emergency kit", 1.5)
	prompt.Triggered:Connect(function(player)
		if found then
			return
		end
		found = true
		caption(player.DisplayName .. " found flashlights for everyone!")
		services.EquipmentService:EnableLoadouts()
		Net.Event("Toast"):FireAllClients("Press F or tap the light button to use your light", "Info")
	end)
	waitUntil(function()
		return found
	end)
	prompt:Destroy()
end

local function beatTrail()
	setObjective("Follow the footprints into the woods", refs.StationDoor)
	caption("The footprints lead away from the road, deeper into the pines.")

	waitUntil(function()
		return anyPlayerWithin(refs.TrailMidpoint, 22) ~= nil
	end)
	effect("Thunder", { soundId = Assets.Sounds.Thunder })
	services.CreatureService.watcher:Reveal(refs.WatcherReveal)
	task.wait(0.6)
	caption("Something tall is standing between the trees. Watching.")

	waitUntil(function()
		return anyPlayerWithin(refs.StationDoor, 26) ~= nil
	end)
	state.checkpoint = refs.StationCheckpoint
	services.CreatureService.watcher:SetMode("Stalk")
	caption("A ranger station. The windows are dark.")
end

local function beatFuses()
	local needed = CH.FuseCount
	local inserted = 0
	local function update()
		setObjective(string.format("Restore power: find fuses and insert them (%d/%d)", inserted, needed), refs.FuseBox.Position)
	end
	update()
	caption("The fuse box is empty. There must be spare fuses around the clearing.")

	-- Pick fuse locations at random so every run is a little different.
	local spots = table.clone(refs.FuseSpots)
	for i = #spots, 2, -1 do
		local j = math.random(i)
		spots[i], spots[j] = spots[j], spots[i]
	end
	for i = 1, needed do
		local fuse = Builder.part(refs.Map, "Fuse", Vector3.new(0.6, 1.2, 0.6), spots[i], Color3.fromRGB(255, 210, 70), Enum.Material.Neon)
		fuse.CanCollide = false
		local glow = Instance.new("PointLight")
		glow.Range = 6
		glow.Brightness = 0.6
		glow.Color = Color3.fromRGB(255, 210, 70)
		glow.Parent = fuse
		local prompt = Builder.prompt(fuse, "Pick up", "Fuse")
		prompt.Triggered:Connect(function(player)
			if fuse.Parent then
				fuse:Destroy()
				player:SetAttribute("Fuses", (player:GetAttribute("Fuses") or 0) + 1)
				Net.Event("Toast"):FireClient(player, "Picked up a fuse. Bring it to the fuse box.", "Info")
			end
		end)
	end

	local boxPrompt = Builder.prompt(refs.FuseBox, "Insert fuses", "Fuse box", 0.8)
	boxPrompt.Triggered:Connect(function(player)
		local carried = player:GetAttribute("Fuses") or 0
		if carried <= 0 then
			Net.Event("Toast"):FireClient(player, "You don't have any fuses.", "Warning")
			return
		end
		player:SetAttribute("Fuses", nil)
		inserted = math.min(needed, inserted + carried)
		EventBus.Fire("FuseInserted", player, carried)
		update()
	end)

	waitUntil(function()
		return inserted >= needed
	end)
	boxPrompt:Destroy()

	state.power = true
	for _, entry in refs.StationLights do
		entry.light.Enabled = true
		entry.part.Material = Enum.Material.Neon
	end
	services.EquipmentService:RechargeAll()
	effect("PowerOn", { soundId = Assets.Sounds.PowerOn })
	caption("The lights buzz on. Batteries recharge. Somewhere, a radio crackles.")
end

local function beatRadio()
	local seed = os.time() + #game.JobId * 7919
	local code, clues = PuzzleCode.generate(seed, 3)
	state.radioCode = code
	state.radioSolved = false

	local ordinal = { "FIRST", "SECOND", "THIRD" }
	for i, clue in clues do
		notePrompt(refs.ClueNotes[i], clue.symbol .. " check-in sheet",
			string.format("%s POST - nightly check-in\n\nAll clear. Wind picking up.\n\nEmergency channel, %s digit: %d", string.upper(clue.symbol), ordinal[clue.order], clue.digit))
	end
	notePrompt(refs.RangerLog, "Ranger Hale's log",
		"Day 41. The trail cameras keep catching something tall at the tree line. Always facing the camera. Never moving.\n\nIf the power goes out: the emergency channel is split across the three check-in sheets on these walls. FIRST, SECOND, THIRD.\n\nAnd never, ever answer a voice from the trees. Even if you know it.")

	setObjective("Find the emergency channel and call for help on the radio", refs.Radio.Position)
	local prompt = Builder.prompt(refs.Radio, "Use", "Radio")
	prompt.Triggered:Connect(function(player)
		Net.Event("OpenPanel"):FireClient(player, "Radio", { digits = #code })
	end)

	waitUntil(function()
		return state.radioSolved
	end)
	prompt:Destroy()
	Net.Event("OpenPanel"):FireAllClients("Close", {})

	effect("RadioStatic", { soundId = Assets.Sounds.RadioStatic })
	local lines = {
		{ "[Radio] ...Station 7? This is Ranger Hale. Who's on this channel?", 4 },
		{ "[Radio] Kids? Listen to me carefully. Stay together. Keep your lights on.", 4.5 },
		{ "[Radio] Take the old service road to the bridge. I'll meet you on Route 9.", 4.5 },
		{ "[Radio] And if one of your friends calls you from the trees... don't answer. It isn't them.", 5 },
		{ "[Radio static]", 2.5 },
	}
	for _, line in lines do
		caption(line[1], "Radio")
		task.wait(line[2])
	end
	local players = Players:GetPlayers()
	local victim = players[math.random(#players)]
	caption(string.format("[Radio, a different voice] \"%s? It's me. I'm outside. Come out, please.\"", victim.DisplayName), "Mimic")
	services.FearService:Spike(victim, 15)

	services.CreatureService.mimic:SetActive(true)
	task.spawn(function()
		task.wait(6)
		local present = Players:GetPlayers()
		if #present > 0 and services.CreatureService.mimic then
			services.CreatureService.mimic:ShowDecoy(present[math.random(#present)], present)
		end
	end)
end

local function beatMap()
	setObjective("Check the trail map on the table", refs.MapTable.Position)
	local read = false
	local prompt = Builder.prompt(refs.MapTable, "Study", "Trail map")
	prompt.Triggered:Connect(function(player)
		read = true
		openNote(player, "Trail map", "The OLD SERVICE ROAD runs from the station back to the main road, then north to the BRIDGE.\n\nRoute 9 is just across the river.\n\nSomeone has drawn a tall stick figure next to the bridge. Over and over.")
	end)
	waitUntil(function()
		return read
	end)
	prompt:Destroy()
	state.checkpoint = refs.ChaseCheckpoint
	setObjective("Follow the service road to the bridge", refs.BridgePosition)
	caption("The road out is past the bridge. Stay together.")
end

local function escape(player: Player)
	if player:GetAttribute("Escaped") then
		return
	end
	player:SetAttribute("Escaped", true)
	if services.PlayerStateService:IsDowned(player) then
		services.PlayerStateService:Revive(player, nil)
	end
	local character = player.Character
	if character then
		character:PivotTo(refs.ExitHold * CFrame.new(math.random(-6, 6), 0, math.random(-3, 3)))
	end
	caption(player.DisplayName .. " made it across the bridge!")
end

local function beatChase()
	waitUntil(function()
		return anyPlayerWithin(refs.ChaseTrigger, 20) ~= nil
	end)

	state.phase = "Chase"
	local watcher = services.CreatureService.watcher
	services.CreatureService.mimic:SetActive(false)
	watcher:Reveal(CFrame.new(refs.StationDoor + Vector3.new(-6, 0, 0)))
	watcher:SetMode("Chase")
	effect("ChaseStart", { soundId = Assets.Sounds.ChaseMusic })
	caption("It's coming. RUN!")
	services.OnboardingService:HintAll("Sprint")
	setObjective("RUN to the bridge!", refs.BridgePosition)

	local chaseStart = os.clock()
	local firstEscape: number? = nil
	local spedUp = false
	local retreated = false

	while true do
		task.wait(0.25)
		local remaining = 0
		local active = 0
		for _, player in Players:GetPlayers() do
			if not player:GetAttribute("Escaped") then
				remaining += 1
				local root = rootOf(player)
				if root and insideRegion(root.Position, refs.ExitZone) then
					escape(player)
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
					escape(player)
				end
			end
			break
		end
		if not spedUp and os.clock() - chaseStart > CH.ChaseTimeLimit then
			spedUp = true
			watcher:AddSpeed(3)
			caption("The storm is getting worse. Hurry!")
		end
		-- Everyone still running is down: it backs off until they're back up.
		if active == 0 and not retreated then
			retreated = true
			watcher:SetMode("Hidden")
		elseif active > 0 and retreated then
			retreated = false
			task.wait(4)
			watcher:Reveal(CFrame.new(refs.StationDoor + Vector3.new(-6, 0, 0)))
			watcher:SetMode("Chase")
		end
	end

	watcher:SetMode("Hidden")
	effect("ChaseEnd", {})
end

local function beatEnding()
	state.phase = "Ending"
	setObjective("", nil)
	local userIds = {}
	for _, player in Players:GetPlayers() do
		table.insert(userIds, player.UserId)
	end
	Net.Event("PhotoEnding"):FireAllClients({
		userIds = userIds,
		hold = CH.EndingPhotoHold,
		text = "The rescue ranger found this photo tucked behind the bus visor.\nIt shows all of you beside the crashed bus. Tonight.\n\nNobody remembers taking it. And between the trees behind you...",
	})
	task.wait(CH.EndingPhotoHold + 4)

	local elapsed = math.floor(os.clock() - state.startedAt)
	for _, player in Players:GetPlayers() do
		if state.participants[player] then
			local flawless = not state.caught[player]
			local data = services.DataService:Get(player)
			local firstClear = data and not data.FirstClear
			local embers = services.EconomyService:Add(player, GameConfig.Rewards.ChapterCompleteEmbers, "Chapter1Complete", true)
			if firstClear then
				services.DataService:Update(player, function(d)
					d.FirstClear = true
				end)
				embers += services.EconomyService:Add(player, GameConfig.Rewards.FirstClearBonusEmbers, "Chapter1FirstClear", true)
			end
			local xp = GameConfig.Rewards.ChapterCompleteXP + (if flawless then GameConfig.Rewards.SurvivedWithoutDownBonusXP else 0)
			services.ProgressionService:AddXP(player, xp)
			EventBus.Fire("ChapterCompleted", player)
			if flawless then
				EventBus.Fire("FlawlessClear", player)
			end
			Net.Event("ChapterResult"):FireClient(player, {
				embers = embers,
				xp = xp,
				flawless = flawless,
				firstClear = firstClear,
				seconds = elapsed,
				canReturn = GameConfig.Places.Lobby ~= 0,
				nextIn = CH.ReturnToLobbyDelay,
			})
		end
	end
	task.wait(CH.ReturnToLobbyDelay)
end

----------------------------------------------------------------------------
-- Run loop

local function resetRun()
	if refs and refs.Map then
		refs.Map:Destroy()
	end
	services.CreatureService:Despawn()
	services.EquipmentService:ResetRun()
	services.PlayerStateService:ResetRun()
	services.FearService:ResetAll()
	state.phase = "Waiting"
	state.power = false
	state.radioSolved = false
	table.clear(state.caught)
	table.clear(state.participants)
	for _, player in Players:GetPlayers() do
		player:SetAttribute("Fuses", nil)
	end

	refs = Chapter1Map.Build()
	services.CreatureService:Spawn()
	state.checkpoint = refs.BusSpawns[1]
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
	setObjective("Waiting for everyone to board the bus...", nil)
	waitUntil(function()
		for _, player in Players:GetPlayers() do
			if rootOf(player) then
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
	for i, player in Players:GetPlayers() do
		state.participants[player] = true
		local character = player.Character
		if character then
			character:PivotTo(refs.BusSpawns[(i - 1) % #refs.BusSpawns + 1])
		end
	end
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

local function runChapter()
	resetRun()
	waitForPlayers()
	state.startedAt = os.clock()
	local onboarding = services.OnboardingService
	onboarding:NewRun()
	onboarding:Step(1, "Boarded")
	beatIntro()
	onboarding:Step(2, "IntroWatched")
	onboarding:HintAll("Move")
	onboarding:HintAll("Interact")
	beatDriver()
	onboarding:Step(3, "DriverChecked")
	beatKit()
	onboarding:Step(4, "KitFound")
	onboarding:HintAll("Light")
	beatTrail()
	onboarding:Step(5, "ReachedStation")
	beatFuses()
	onboarding:Step(6, "PowerRestored")
	beatRadio()
	onboarding:Step(7, "RadioSolved")
	beatMap()
	onboarding:Step(8, "MapRead")
	beatChase()
	onboarding:Step(9, "Escaped")
	beatEnding()
	onboarding:Step(10, "ChapterComplete")
end

----------------------------------------------------------------------------
-- Service lifecycle

function ChapterService:Init(registry)
	services = registry

	Net.Event("SubmitRadioCode").OnServerEvent:Connect(function(player, attempt)
		if state.radioSolved or not radioLimiter:Allow(player) or type(attempt) ~= "string" or #attempt > 12 then
			return
		end
		if PuzzleCode.check(state.radioCode, attempt) then
			state.radioSolved = true
			caption(player.DisplayName .. " tuned the radio to the emergency channel.")
		else
			Net.Event("Toast"):FireClient(player, "Only static. Wrong channel.", "Warning")
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
	applyStormLighting()
	task.spawn(thunderLoop)

	local function onCharacter(player: Player, character: Model)
		character:WaitForChild("HumanoidRootPart", 10)
		task.wait()
		placeAtCheckpoint(player)
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
