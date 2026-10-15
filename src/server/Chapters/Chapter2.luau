-- Chapter 2, "The Ranger".
--
--   empty rescue truck -> camp office (The Ranger appears, whistles) -> four torn
--   map pieces -> boathouse padlock -> flare gun -> lookout tower flare (The
--   Ranger stands guard below) -> helicopter: run to the landing pad -> the photo
--
-- The Ranger is a hearing hunter: running and splashing are loud, tents hide you,
-- the office light keeps him out, and a whistle pulls him to whoever blew it.

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)
local Assets = require(Shared.Config.Assets)
local EventBus = require(script.Parent.Parent.EventBus)
local Builder = require(script.Parent.Parent.World.Builder)
local Chapter2Map = require(script.Parent.Parent.World.Chapter2Map)

local Chapter2 = {
	id = 2,
	title = "The Ranger",
	config = GameConfig.Chapter2,
	thunder = false,
}

local CH = GameConfig.Chapter2

function Chapter2.buildMap()
	return Chapter2Map.Build()
end

function Chapter2.spawns(refs)
	return refs.Spawns
end

function Chapter2.applyLighting()
	Lighting.ClockTime = 1.5
	-- Moonlit: you can see the camp, but not what's in the shadows.
	Lighting.Brightness = 1.8
	Lighting.Ambient = Color3.fromRGB(64, 70, 86)
	Lighting.OutdoorAmbient = Color3.fromRGB(98, 108, 130)
	Lighting.EnvironmentDiffuseScale = 0.4
	Lighting.EnvironmentSpecularScale = 0.3
	Lighting.GlobalShadows = true
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
	atmosphere.Density = 0.28
	atmosphere.Offset = 0.15
	atmosphere.Color = Color3.fromRGB(105, 115, 130)
	atmosphere.Decay = Color3.fromRGB(54, 60, 74)
	atmosphere.Glare = 0
	atmosphere.Haze = 1.6
	atmosphere.Parent = Lighting
	local grade = Lighting:FindFirstChild("StormGrade") or Instance.new("ColorCorrectionEffect")
	grade.Name = "StormGrade"
	grade.Saturation = -0.25
	grade.Contrast = 0.06
	grade.Brightness = 0.04
	grade.TintColor = Color3.fromRGB(210, 228, 240)
	grade.Parent = Lighting
end

local function ranger(story)
	return story.services.CreatureService.ranger
end

local function shuffled(list)
	local copy = table.clone(list)
	for i = #copy, 2, -1 do
		local j = math.random(i)
		copy[i], copy[j] = copy[j], copy[i]
	end
	return copy
end

----------------------------------------------------------------------------
-- Beats

local function beatTruck(story)
	local refs = story.refs
	story.services.EquipmentService:EnableLoadouts()
	story.notePrompt(refs.Truck, "Rescue clipboard", "HOLLOW PINES SEARCH & RESCUE\n\nCall: 6 kids, bus off the old forest road. Pick up at Route 9.\n\nDriver's note, scribbled fast: \"Road flooded. Cutting through the campground. Ranger Hale says he'll meet us at the office.\"\n\nThe last line trails off the page.")
	story.caption("The rescue truck's engine is still running. The door is open. Nobody is inside.")
	story.setObjective("Find the camp office", refs.OfficeDoor)
	story.waitUntil(function()
		return story.anyPlayerWithin(refs.CampEntrance, 26) ~= nil
	end)
	story.caption("The campground is flooded. Puddles everywhere, tents flapping in the wind.")
	story.services.OnboardingService:HintAll("Noise")
end

local function beatOffice(story)
	local refs, services = story.refs, story.services
	story.waitUntil(function()
		return story.anyPlayerWithin(refs.OfficeDoor, 24) ~= nil
	end)
	story.addSafeZone(refs.OfficeSafeZone)
	story.setCheckpoint(refs.OfficeCheckpoint)
	story.effect("RadioStatic", { soundId = Assets.Sounds.RadioStatic })
	local lines = {
		{ "[Walkie] ...anyone at Hollow Pines camp? This is the rescue crew. We lost our driver.", 4.5 },
		{ "[Walkie] Ranger Hale is out there, but he isn't himself. Don't let him find you.", 4.5 },
		{ "[Walkie] He hears EVERYTHING. Don't run. Stay out of the water. Lights make you easy to see.", 5 },
		{ "[Walkie] There's a flare gun in the boathouse. Fire it from the lookout tower and we'll come.", 5 },
	}
	for _, line in lines do
		story.caption(line[1], "Radio")
		task.wait(line[2])
	end

	-- The Ranger steps out of the trees on the far side of the camp.
	local hunter = ranger(story)
	hunter:PlaceAt(refs.PatrolPoints[#refs.PatrolPoints])
	hunter:SetMode("Patrol")
	story.caption("A lantern is bobbing between the tents. Slowly. Listening.")
	story.caption("The office lights are on. He won't come inside.", "Hint")

	story.notePrompt(refs.Noticeboard, "Camp rules", "CAMP RULES\n\n1. Lights out at 10.\n2. Stay quiet after dark.\n3. Never go to the lake alone.\n\nUnder it, in pencil: \"he can't see you in the tents if you keep still\"")
	story.setObjective("Search the lost and found box", refs.LostAndFound.Position)
	local finder = story.waitForPrompt(refs.LostAndFound, "Search", "Lost and found", 1)
	for _, player in Players:GetPlayers() do
		services.EquipmentService:GiveStoryItem(player, "Whistle")
	end
	story.caption(finder.DisplayName .. " found a box of camp whistles. One for everyone.")
	services.OnboardingService:HintAll("Whistle")
end

local function beatMapPieces(story)
	local refs = story.refs
	local needed = CH.MapPieceCount
	local code, clues = story.generateCode(needed)
	local found = 0
	local ordinal = { "FIRST", "SECOND", "THIRD", "FOURTH" }

	story.notePrompt(refs.HaleLog, "Ranger Hale's log",
		"Day 44. Something followed me back from the bridge. I keep hearing my own voice in the trees.\n\nI locked the flare gun in the boathouse and tore up the lock code with the camp map. Four pieces. Hid them around the camp so HE can't use the flares.\n\nIf you're reading this: I'm sorry. Whatever is wearing my coat isn't me anymore.")

	local function update()
		story.setObjective(string.format("Find the torn map pieces around the camp (%d/%d)", found, needed), nil)
	end
	update()
	story.caption("Ranger Hale's log is on the desk. The boathouse lock code is split across four map pieces.")

	local spots = shuffled(refs.MapPieceSpots)
	for i = 1, needed do
		local clue = clues[i]
		local piece = Builder.part(refs.Map, "MapPiece", Vector3.new(1.4, 0.15, 1.1), CFrame.new(spots[i]) * CFrame.Angles(0, math.random() * math.pi, 0), Color3.fromRGB(235, 220, 180), Enum.Material.SmoothPlastic)
		piece.CanCollide = false
		local glow = Instance.new("PointLight")
		glow.Range = 5
		glow.Brightness = 0.5
		glow.Color = Color3.fromRGB(255, 240, 200)
		glow.Parent = piece
		local prompt = Builder.prompt(piece, "Pick up", "Torn map piece")
		prompt.Triggered:Connect(function(player)
			if not piece.Parent then
				return
			end
			piece:Destroy()
			found += 1
			EventBus.Fire("MapPieceFound", player)
			story.openNote(player, "Torn map piece (" .. clue.symbol .. ")",
				string.format("A corner of the camp map, damp and muddy.\n\nBoathouse lock, %s number: %d\n\nSomeone drew a lantern next to it and crossed it out.", ordinal[clue.order], clue.digit))
			story.caption(string.format("%s found a map piece: the %s number is %d.", player.DisplayName, string.lower(ordinal[clue.order]), clue.digit))
			update()
		end)
	end

	story.waitUntil(function()
		return found >= needed
	end)
	return code
end

local function beatBoathouse(story, code: string)
	local refs = story.refs
	local opened = false
	story.expectCode(code, function(player)
		opened = true
		story.caption(player.DisplayName .. " opened the padlock.")
	end)
	story.setObjective("Open the boathouse padlock by the lake", refs.Padlock.Position)
	story.setCheckpoint(CFrame.new(refs.BoathouseFront + Vector3.new(0, 3, -6)))
	local prompt = Builder.prompt(refs.Padlock, "Unlock", "Padlock")
	prompt.Triggered:Connect(function(player)
		story.openCodePanel(player, "🔒 Boathouse padlock", "Enter the four numbers from the map pieces")
	end)
	story.waitUntil(function()
		return opened
	end)
	prompt:Destroy()
	story.effect("Padlock", { soundId = Assets.Sounds.Padlock })
	refs.Padlock:Destroy()
	refs.BoathouseDoor.CanCollide = false
	refs.BoathouseDoor.Transparency = 1

	story.setObjective("Take the flare gun", refs.FlareCase.Position)
	local taker = story.waitForPrompt(refs.FlareCase, "Take", "Flare gun", 0.8)
	refs.FlareCase.Color = Color3.fromRGB(80, 30, 24)
	story.caption(taker.DisplayName .. " has the flare gun. Get to the top of the lookout tower!")
	return taker
end

local function beatTower(story)
	local refs, services = story.refs, story.services
	story.setObjective("Climb the lookout tower and fire the flare", refs.FlareSpot.Position)
	story.caption("Walk into the ladder to climb it.", "Hint")
	local shooter = story.waitForPrompt(refs.FlareSpot, "Fire flare", "Flare mount", 1)
	story.setCheckpoint(CFrame.new(refs.TowerTopCenter + Vector3.new(0, 3, 0)))
	story.effect("Flare", { soundId = Assets.Sounds.Flare, position = refs.FlareSpot.Position })
	services.NoiseService:Emit(refs.FlareSpot.Position, GameConfig.Noise.Flare, shooter)
	EventBus.Fire("FlareFired", shooter)
	story.caption(shooter.DisplayName .. " fired the flare! The whole sky turns red.")

	local hunter = ranger(story)
	if not hunter:Position() then
		hunter:PlaceAt(refs.PatrolPoints[1])
	end
	hunter:SetMode("Guard", refs.TowerBase)
	task.wait(2)
	story.caption("Every tent, every puddle goes quiet. The lantern turns towards the tower.")
	story.caption("He's coming to the ladder. Get up the tower, he can't climb!", "Hint")

	story.setObjective("Hold out on the tower until the helicopter comes", refs.TowerTopCenter)
	local waited = 0
	local updates = {
		[10] = "[Radio] We see your flare! Hold on, kids.",
		[25] = "[Radio] Landing on the pad by the east field. Be ready to run.",
	}
	while waited < CH.HelicopterDelay do
		task.wait(1)
		waited += 1
		if updates[waited] then
			story.caption(updates[waited], "Radio")
		end
	end
end

local function beatHelicopter(story)
	local refs, services = story.refs, story.services
	local hunter = ranger(story)
	refs.LandingLight.light.Enabled = true
	refs.LandingLight.part.Transparency = 0
	story.effect("Helicopter", { soundId = Assets.Sounds.Helicopter, position = refs.Helipad })
	story.caption("[Rotor blades thunder overhead. A searchlight sweeps the camp.]", "Sound")

	-- The searchlight spooks him away from the ladder for a few seconds.
	hunter:SetMode("Investigate", refs.BoathouseFront)
	story.caption("The Ranger stumbles back from the searchlight. GO, NOW!")
	story.effect("ChaseStart", { soundId = Assets.Sounds.ChaseMusic })
	story.setObjective("RUN to the helicopter landing pad!", refs.Helipad)
	services.OnboardingService:HintAll("Sprint")

	local function hunt()
		if not hunter:Position() then
			hunter:PlaceAt(refs.BoathouseFront)
		end
		hunter:SetMode("Hunt")
	end
	task.delay(8, function()
		if hunter.mode ~= "Hunt" and hunter.mode ~= "Hidden" then
			hunt()
		end
	end)

	story.runEscape({
		exitZone = refs.ExitZone,
		exitHold = refs.ExitHold,
		escapedText = "%s made it onto the helicopter!",
		creature = hunter,
		restart = hunt,
		speedUpAfter = 90,
	})
end

function Chapter2.run(story)
	local onboarding = story.services.OnboardingService
	onboarding:Step(1, "Arrived")
	story.intro({ length = CH.IntroLength })
	onboarding:Step(2, "IntroWatched")
	beatTruck(story)
	onboarding:Step(3, "EnteredCamp")
	beatOffice(story)
	onboarding:Step(4, "ReachedOffice")
	local code = beatMapPieces(story)
	onboarding:Step(5, "MapPiecesFound")
	beatBoathouse(story, code)
	onboarding:Step(6, "FlareGunTaken")
	beatTower(story)
	onboarding:Step(7, "FlareFired")
	beatHelicopter(story)
	onboarding:Step(8, "Escaped")
end

function Chapter2.ending(_story)
	return {
		scene = "Tower",
		text = "The pilot never said a word the whole flight. At the base, a photo was waiting on her seat.\nIt shows the lookout tower from the air. Tonight.\n\nRanger Hale is at the bottom of the ladder, lantern raised. He isn't looking at you.\nHe's looking at the tall shape standing on the tower roof...",
	}
end

return Chapter2
