-- Chapter 1, "The Storm".
--
--   crash -> empty driver's seat -> emergency kit -> footprints (first Watcher
--   sighting) -> ranger station -> 3 fuses -> radio code (Mimic teaser) ->
--   map table -> chase to the bridge -> the photograph

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)
local Assets = require(Shared.Config.Assets)
local Net = require(Shared.Util.Net)
local EventBus = require(script.Parent.Parent.EventBus)
local Builder = require(script.Parent.Parent.World.Builder)
local Chapter1Map = require(script.Parent.Parent.World.Chapter1Map)

local Chapter1 = {
	id = 1,
	title = "The Storm",
	config = GameConfig.Chapter1,
	thunder = true,
}

local CH = GameConfig.Chapter1
local DRIVER = "Mr. Dorsey"

function Chapter1.buildMap()
	return Chapter1Map.Build()
end

function Chapter1.spawns(refs)
	return refs.BusSpawns
end

function Chapter1.applyLighting()
	Lighting.ClockTime = 0.2
	-- Night, but bright enough to see the shapes of trees without a light.
	Lighting.Brightness = 1.6
	Lighting.Ambient = Color3.fromRGB(62, 66, 84)
	Lighting.OutdoorAmbient = Color3.fromRGB(92, 100, 124)
	Lighting.EnvironmentDiffuseScale = 0.35
	Lighting.EnvironmentSpecularScale = 0.2
	Lighting.GlobalShadows = true
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
	atmosphere.Density = 0.3
	atmosphere.Offset = 0.1
	atmosphere.Color = Color3.fromRGB(90, 100, 122)
	atmosphere.Decay = Color3.fromRGB(50, 54, 70)
	atmosphere.Glare = 0
	atmosphere.Haze = 1.4
	atmosphere.Parent = Lighting
	local grade = Lighting:FindFirstChild("StormGrade") or Instance.new("ColorCorrectionEffect")
	grade.Name = "StormGrade"
	grade.Saturation = -0.3
	grade.Contrast = 0.05
	grade.Brightness = 0.04
	grade.TintColor = Color3.fromRGB(215, 225, 255)
	grade.Parent = Lighting
end

----------------------------------------------------------------------------
-- Beats

local function beatDriver(story)
	local refs = story.refs
	story.setObjective("Check on the driver", refs.DriverSeat.Position)
	local checked = false
	local prompt = Builder.prompt(refs.DriverSeat, "Check", "Driver's seat")
	prompt.Triggered:Connect(function(player)
		story.openNote(player, "The driver's seat", DRIVER .. " is gone.\n\nThe seatbelt has been cut clean through. The bus door was forced open from the OUTSIDE.\n\nThere are muddy footprints leading into the trees.")
		if not checked then
			checked = true
			story.caption(player.DisplayName .. " checked the driver's seat. " .. DRIVER .. " is missing.")
		end
	end)
	story.notePrompt(refs.BusNote, "Field trip itinerary", "HOLLOW PINES MIDDLE SCHOOL - Nature Reserve Trip\n\n4:00 PM  Leave the reserve\n4:30 PM  Shortcut via the old forest road (bridge closed?)\n\nRemember: stay with your buddy at ALL times.\n\nSomeone has scribbled at the bottom: \"who is the extra kid in the back seat?\"")
	story.waitUntil(function()
		return checked
	end)
	prompt:Destroy()
end

local function beatKit(story)
	story.setObjective("Search the emergency kit at the back of the bus", story.refs.KitCrate.Position)
	local finder = story.waitForPrompt(story.refs.KitCrate, "Search", "Emergency kit", 1.5)
	story.caption(finder.DisplayName .. " found flashlights for everyone!")
	story.services.EquipmentService:EnableLoadouts()
	story.toastAll("Press F or tap the light button to use your light")
end

local function beatTrail(story)
	local refs, services = story.refs, story.services
	story.setObjective("Follow the footprints into the woods", refs.StationDoor)
	story.caption("The footprints lead away from the road, deeper into the pines.")

	story.waitUntil(function()
		return story.anyPlayerWithin(refs.TrailMidpoint, 22) ~= nil
	end)
	story.effect("Thunder", { soundId = Assets.Sounds.Thunder })
	services.CreatureService.watcher:Reveal(refs.WatcherReveal)
	task.wait(0.6)
	story.caption("Something tall is standing between the trees. Watching.")

	story.waitUntil(function()
		return story.anyPlayerWithin(refs.StationDoor, 26) ~= nil
	end)
	story.setCheckpoint(refs.StationCheckpoint)
	services.CreatureService.watcher:SetMode("Stalk")
	story.caption("A ranger station. The windows are dark.")
end

local function beatFuses(story)
	local refs, services = story.refs, story.services
	local needed = CH.FuseCount
	local inserted = 0
	local function update()
		story.setObjective(string.format("Restore power: find fuses and insert them (%d/%d)", inserted, needed), refs.FuseBox.Position)
	end
	update()
	story.caption("The fuse box is empty. There must be spare fuses around the clearing.")

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

	story.waitUntil(function()
		return inserted >= needed
	end)
	boxPrompt:Destroy()

	story.addSafeZone(refs.SafeZone)
	for _, entry in refs.StationLights do
		entry.light.Enabled = true
		entry.part.Material = Enum.Material.Neon
	end
	services.EquipmentService:RechargeAll()
	story.effect("PowerOn", { soundId = Assets.Sounds.PowerOn })
	story.caption("The lights buzz on. Batteries recharge. Somewhere, a radio crackles.")
end

local function beatRadio(story)
	local refs, services = story.refs, story.services
	local code, clues = story.generateCode(3)
	local solved = false
	story.expectCode(code, function(player)
		solved = true
		story.caption(player.DisplayName .. " tuned the radio to the emergency channel.")
	end)

	local ordinal = { "FIRST", "SECOND", "THIRD" }
	for i, clue in clues do
		story.notePrompt(refs.ClueNotes[i], clue.symbol .. " check-in sheet",
			string.format("%s POST - nightly check-in\n\nAll clear. Wind picking up.\n\nEmergency channel, %s digit: %d", string.upper(clue.symbol), ordinal[clue.order], clue.digit))
	end
	story.notePrompt(refs.RangerLog, "Ranger Hale's log",
		"Day 41. The trail cameras keep catching something tall at the tree line. Always facing the camera. Never moving.\n\nIf the power goes out: the emergency channel is split across the three check-in sheets on these walls. FIRST, SECOND, THIRD.\n\nAnd never, ever answer a voice from the trees. Even if you know it.")

	story.setObjective("Find the emergency channel and call for help on the radio", refs.Radio.Position)
	local prompt = Builder.prompt(refs.Radio, "Use", "Radio")
	prompt.Triggered:Connect(function(player)
		story.openCodePanel(player, "📻 Emergency radio", "Set the channel from the check-in sheets")
	end)
	story.waitUntil(function()
		return solved
	end)
	prompt:Destroy()

	story.effect("RadioStatic", { soundId = Assets.Sounds.RadioStatic })
	local lines = {
		{ "[Radio] ...Station 7? This is Ranger Hale. Who's on this channel?", 4 },
		{ "[Radio] Kids? Listen to me carefully. Stay together. Keep your lights on.", 4.5 },
		{ "[Radio] Take the old service road to the bridge. I'll meet you on Route 9.", 4.5 },
		{ "[Radio] And if one of your friends calls you from the trees... don't answer. It isn't them.", 5 },
		{ "[Radio static]", 2.5 },
	}
	for _, line in lines do
		story.caption(line[1], "Radio")
		task.wait(line[2])
	end
	local players = Players:GetPlayers()
	if #players > 0 then
		local victim = players[math.random(#players)]
		story.caption(string.format("[Radio, a different voice] \"%s? It's me. I'm outside. Come out, please.\"", victim.DisplayName), "Mimic")
		services.FearService:Spike(victim, 15)
	end

	services.CreatureService.mimic:SetActive(true)
	task.spawn(function()
		task.wait(6)
		local present = Players:GetPlayers()
		if #present > 0 and services.CreatureService.mimic then
			services.CreatureService.mimic:ShowDecoy(present[math.random(#present)], present)
		end
	end)
end

local function beatMap(story)
	local refs = story.refs
	story.setObjective("Check the trail map on the table", refs.MapTable.Position)
	local reader = story.waitForPrompt(refs.MapTable, "Study", "Trail map")
	story.openNote(reader, "Trail map", "The OLD SERVICE ROAD runs from the station back to the main road, then north to the BRIDGE.\n\nRoute 9 is just across the river.\n\nSomeone has drawn a tall stick figure next to the bridge. Over and over.")
	story.setCheckpoint(refs.ChaseCheckpoint)
	story.setObjective("Follow the service road to the bridge", refs.BridgePosition)
	story.caption("The road out is past the bridge. Stay together.")
end

local function beatChase(story)
	local refs, services = story.refs, story.services
	story.waitUntil(function()
		return story.anyPlayerWithin(refs.ChaseTrigger, 20) ~= nil
	end)

	local watcher = services.CreatureService.watcher
	local function release()
		watcher:Reveal(CFrame.new(refs.StationDoor + Vector3.new(-6, 0, 0)))
		watcher:SetMode("Chase")
	end
	services.CreatureService.mimic:SetActive(false)
	release()
	story.effect("ChaseStart", { soundId = Assets.Sounds.ChaseMusic })
	story.caption("It's coming. RUN!")
	services.OnboardingService:HintAll("Sprint")
	story.setObjective("RUN to the bridge!", refs.BridgePosition)

	story.runEscape({
		exitZone = refs.ExitZone,
		exitHold = refs.ExitHold,
		escapedText = "%s made it across the bridge!",
		creature = watcher,
		restart = release,
		speedUpAfter = CH.ChaseTimeLimit,
	})
end

function Chapter1.run(story)
	local onboarding = story.services.OnboardingService
	onboarding:Step(1, "Boarded")
	story.intro({ length = CH.IntroLength, crashSound = Assets.Sounds.BusCrash })
	onboarding:Step(2, "IntroWatched")
	onboarding:HintAll("Move")
	onboarding:HintAll("Interact")
	beatDriver(story)
	onboarding:Step(3, "DriverChecked")
	beatKit(story)
	onboarding:Step(4, "KitFound")
	onboarding:HintAll("Light")
	beatTrail(story)
	onboarding:Step(5, "ReachedStation")
	beatFuses(story)
	onboarding:Step(6, "PowerRestored")
	beatRadio(story)
	onboarding:Step(7, "RadioSolved")
	beatMap(story)
	onboarding:Step(8, "MapRead")
	beatChase(story)
	onboarding:Step(9, "Escaped")
end

function Chapter1.ending(_story)
	return {
		scene = "Bus",
		text = "The rescue ranger found this photo tucked behind the bus visor.\nIt shows all of you beside the crashed bus. Tonight.\n\nNobody remembers taking it. And between the trees behind you...",
	}
end

return Chapter1
