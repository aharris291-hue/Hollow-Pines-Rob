-- Chapter 3, "Voices".
--
--   the helicopter in the field, pilot gone -> Millbrook in the fog -> the lit
--   general store (Hale's tape: the secret handshake) -> a copy of a friend walks
--   out of the fog -> three tapes give the signal order -> ring the chapel bell,
--   school bell and sawmill whistle in that order -> the ferry answers -> the copy
--   stops pretending: run for the dock -> the photograph
--
-- The Mimic now walks: it wears a player's face and catches anyone it finds
-- alone. Stay together, and when unsure, offer the handshake.

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)
local Assets = require(Shared.Config.Assets)
local Trust = require(Shared.Util.Trust)
local EventBus = require(script.Parent.Parent.EventBus)
local Builder = require(script.Parent.Parent.World.Builder)
local Chapter3Map = require(script.Parent.Parent.World.Chapter3Map)

local Chapter3 = {
	id = 3,
	title = "Voices",
	config = GameConfig.Chapter3,
	thunder = false,
}

local CH = GameConfig.Chapter3
local SIGNALS = { "Chapel", "School", "Mill" }
local ORDINAL = { "FIRST", "SECOND", "THIRD" }

function Chapter3.buildMap()
	return Chapter3Map.Build()
end

function Chapter3.spawns(refs)
	return refs.Spawns
end

function Chapter3.applyLighting()
	-- Grey dawn and thick, pale fog: easy to see your feet, hard to see who's coming.
	Lighting.ClockTime = 6.1
	Lighting.Brightness = 2
	Lighting.Ambient = Color3.fromRGB(80, 84, 96)
	Lighting.OutdoorAmbient = Color3.fromRGB(120, 126, 140)
	Lighting.EnvironmentDiffuseScale = 0.45
	Lighting.EnvironmentSpecularScale = 0.3
	Lighting.GlobalShadows = true
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
	atmosphere.Density = 0.5
	atmosphere.Offset = 0.05
	atmosphere.Color = Color3.fromRGB(190, 196, 205)
	atmosphere.Decay = Color3.fromRGB(120, 126, 138)
	atmosphere.Glare = 0
	atmosphere.Haze = 2.4
	atmosphere.Parent = Lighting
	local grade = Lighting:FindFirstChild("StormGrade") or Instance.new("ColorCorrectionEffect")
	grade.Name = "StormGrade"
	grade.Saturation = -0.35
	grade.Contrast = 0.04
	grade.Brightness = 0.03
	grade.TintColor = Color3.fromRGB(225, 232, 240)
	grade.Parent = Lighting
end

local function shuffled(list)
	local copy = table.clone(list)
	for i = #copy, 2, -1 do
		local j = math.random(i)
		copy[i], copy[j] = copy[j], copy[i]
	end
	return copy
end

-- Every so often a teammate's walkie ping comes from somewhere they've never been.
local function startFakePings(story)
	task.spawn(function()
		while story.services.ChapterService:IsGameplayActive() do
			task.wait(math.random(40, 70))
			local players = Players:GetPlayers()
			local mimic = story.services.CreatureService.mimic
			if #players >= 2 and mimic and story.services.ChapterService:IsGameplayActive() then
				local from = players[math.random(#players)]
				local spot = story.refs.CopySpawns[math.random(#story.refs.CopySpawns)]
				mimic:FakePing(players, from, spot)
			end
		end
	end)
end

----------------------------------------------------------------------------
-- Beats

local function beatLanding(story)
	local refs = story.refs
	story.services.EquipmentService:EnableLoadouts()
	story.notePrompt(refs.PilotSeat, "Flight log", "RESCUE FLIGHT 12\n\nPickup: Hollow Pines lookout tower, 6 kids.\nDestination: Route 9 hospital.\n\nThe last line is in different handwriting:\n\"Change of plan. Land at Millbrook. They'll be safe there.\"\n\nThe headset is still warm.")
	story.caption("The pilot's seat is empty. The headset is swinging. Outside, nothing but fog.")
	story.setObjective("Head into the village", refs.VillageEdge)
	story.waitUntil(function()
		return story.anyPlayerWithin(refs.VillageEdge, 24) ~= nil
	end)
	story.caption("A wooden sign: MILLBROOK, POP. 212. Every window is dark except one.")
	local mimic = story.services.CreatureService.mimic
	mimic:SetActive(true)
	startFakePings(story)
end

local function beatStore(story)
	local refs, services = story.refs, story.services
	story.setObjective("Get to the lit general store", refs.StoreDoor)
	story.waitUntil(function()
		return story.anyPlayerWithin(refs.StoreDoor, 22) ~= nil
	end)
	story.addSafeZone(refs.StoreSafeZone)
	story.setCheckpoint(refs.StoreCheckpoint)
	story.notePrompt(refs.HandshakePoster, "Neighbourhood Watch poster", "NOT SURE IT'S THEM?\n\nMillbrook families: make up a handshake only your family knows.\nIf they can't do it, close the door.\n\nSomeone has written underneath: \"it can copy faces. it can't copy that.\"")

	story.setObjective("Play the tape on the counter", refs.HaleTape.Position)
	story.waitForPrompt(refs.HaleTape, "Play", "Tape recorder", 0.6)
	story.effect("RadioStatic", { soundId = Assets.Sounds.RadioStatic })
	local lines = {
		{ "[Tape, Ranger Hale] If you found this, you got past me at the camp. I'm sorry for that.", 4.5 },
		{ "[Tape] The thing in the trees doesn't just borrow voices any more. It walks around in people.", 4.5 },
		{ "[Tape] It can wear your friend's face. But it can't shake hands. Never could.", 4 },
		{ "[Tape] The ferry comes if you ring the three signals in the right order. I hid the order on tapes around town.", 5 },
		{ "[Tape] And stay together. It only takes the ones who wander off.", 4 },
	}
	for _, line in lines do
		story.caption(line[1], "Radio")
		task.wait(line[2])
	end
	services.OnboardingService:HintAll("Handshake")

	-- Its first appearance is staged: a "friend" waiting in the street.
	local copy = services.CreatureService.copy
	local players = Players:GetPlayers()
	if #players > 0 and copy then
		local wearing = players[math.random(#players)]
		copy:Appear(wearing, refs.StoreDoor + Vector3.new(22, 0, math.random(-6, 6)), refs.StoreDoor)
		copy:SetMode("Stalk")
		story.caption(string.format("Someone is standing in the street, looking at the store. It looks like %s.", wearing.DisplayName))
		story.caption("Not sure? Walk up and press H, or tap Shake. A real friend shakes back.", "Hint")
	end
end

local function beatTapes(story)
	local refs = story.refs
	local order = shuffled(SIGNALS)
	local found = 0
	local function update()
		story.setObjective(string.format("Find Hale's tapes around the village (%d/%d)", found, CH.TapeCount), nil)
	end
	update()

	local spots = shuffled(refs.TapeSpots)
	for i = 1, CH.TapeCount do
		local signal = refs.Signals[order[i]]
		local tape = Builder.part(refs.Map, "Tape", Vector3.new(1.6, 0.7, 1.1), CFrame.new(spots[i]), Color3.fromRGB(40, 40, 46), Enum.Material.Plastic)
		tape.CanCollide = false
		local glow = Instance.new("PointLight")
		glow.Range = 6
		glow.Brightness = 0.8
		glow.Color = Color3.fromRGB(255, 120, 90)
		glow.Parent = tape
		local prompt = Builder.prompt(tape, "Play", "Hale's tape")
		prompt.Triggered:Connect(function(player)
			if not tape.Parent then
				return
			end
			tape:Destroy()
			found += 1
			EventBus.Fire("TapeFound", player)
			story.openNote(player, string.format("Tape %d of %d", i, CH.TapeCount),
				string.format("[Ranger Hale, whispering]\n\n\"Signal number %d. Ring the %s %s.\"\n\nUnder the hiss, very quietly, a second voice repeats every word a moment after him.", i, signal.name, ORDINAL[i]))
			story.caption(string.format("%s found a tape: ring the %s %s.", player.DisplayName, signal.name, ORDINAL[i]))
			update()
		end)
	end
	story.waitUntil(function()
		return found >= CH.TapeCount
	end)
	return order
end

local function beatSignals(story, order)
	local refs, services = story.refs, story.services
	local sequence = Trust.newSequence(order)
	local names = {}
	for i, id in order do
		names[i] = refs.Signals[id].name
	end
	local function update()
		story.setObjective(string.format("Ring the signals in order: %s (%d/3)", table.concat(names, ", "), sequence:Progress()), refs.Signals[order[sequence:Progress() + 1] or order[3]].position)
	end
	update()

	local done = false
	local prompts = {}
	for _, id in SIGNALS do
		local signal = refs.Signals[id]
		local prompt = Builder.prompt(signal.part, "Ring", signal.name, 0.8)
		prompts[id] = prompt
		prompt.Triggered:Connect(function(player)
			if done then
				return
			end
			story.effect("Bell", { soundId = Assets.Sounds.Bell, position = signal.bell.Position })
			local result = sequence:Press(id)
			if result == "wrong" then
				story.caption(string.format("%s rang the %s. Wrong order... the sound dies in the fog. Start again.", player.DisplayName, signal.name))
				services.FearService:Spike(player, 10)
				-- Something heard that.
				local copy = services.CreatureService.copy
				if copy and not copy:Position() then
					copy:Vanish(3)
				end
			else
				story.caption(string.format("%s rang the %s.", player.DisplayName, signal.name))
				done = result == "done"
			end
			update()
		end)
	end
	story.waitUntil(function()
		return done
	end)
	for _, prompt in prompts do
		prompt:Destroy()
	end
	story.effect("FerryHorn", { soundId = Assets.Sounds.FerryHorn })
	story.caption("[Far across the lake, a ferry horn answers. Twice.]", "Sound")
end

local function beatFerry(story)
	local refs, services = story.refs, story.services
	local copy = services.CreatureService.copy
	local mimic = services.CreatureService.mimic

	story.caption("The copy stops pretending. Every voice in the fog is calling your names.", "Mimic")
	story.caption("The store is safe. When the ferry docks, everyone run for it!", "Hint")
	story.setObjective("Hold out until the ferry reaches the dock", refs.Dock)
	story.setCheckpoint(refs.StoreCheckpoint)
	if copy then
		copy:SetMode("Hunt")
	end

	-- The ferry glides in out of the fog.
	local hull = refs.Ferry.PrimaryPart
	TweenService:Create(hull, TweenInfo.new(CH.FerryDelay, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), { CFrame = refs.FerryDocked }):Play()
	task.wait(CH.FerryDelay)
	story.effect("FerryHorn", { soundId = Assets.Sounds.FerryHorn })
	story.effect("ChaseStart", { soundId = Assets.Sounds.ChaseMusic })
	story.caption("The ferry is at the dock. RUN!")
	story.setObjective("RUN to the ferry!", refs.Dock)
	services.OnboardingService:HintAll("Sprint")
	if mimic then
		mimic:SetActive(false)
	end

	story.runEscape({
		exitZone = refs.ExitZone,
		exitHold = refs.ExitHold,
		escapedText = "%s made it onto the ferry!",
		creature = copy,
		restart = function()
			copy:SetMode("Hunt")
		end,
		speedUpAfter = 75,
	})
end

function Chapter3.run(story)
	local onboarding = story.services.OnboardingService
	onboarding:Step(1, "Arrived")
	story.intro({ length = CH.IntroLength })
	onboarding:Step(2, "IntroWatched")
	beatLanding(story)
	onboarding:Step(3, "EnteredVillage")
	beatStore(story)
	onboarding:Step(4, "TapeHeard")
	local order = beatTapes(story)
	onboarding:Step(5, "TapesFound")
	beatSignals(story, order)
	onboarding:Step(6, "SignalsRung")
	beatFerry(story)
	onboarding:Step(7, "Escaped")
end

function Chapter3.ending(_story)
	return {
		scene = "Ferry",
		text = "The ferryman took a photo of you all at the rail, for the newspaper.\nHe gave it to you when you landed.\n\nCount the people at the rail. There's one more of you than there should be.\nAnd one of them doesn't have a face.",
	}
end

return Chapter3
