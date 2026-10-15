-- Chapter 4, "The Hollow" (finale).
--
--   the far shore -> the lit cabin (Hale's old journal: the truth) -> wake the
--   three lost adults with warm light, each gives a flame -> carry the flames
--   past The Hollow One's gaze to the three stone braziers -> it remembers, the
--   forest lets go -> The Watcher's last chase to the ferry -> home
--
-- The Hollow One is the oldest tree in the forest, and it is lonely. The
-- Watcher, the voices and whatever wore Ranger Hale's coat were all it, looking
-- for company. Nobody is hurt; the lost come home.

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)
local Assets = require(Shared.Config.Assets)
local Net = require(Shared.Util.Net)
local EventBus = require(script.Parent.Parent.EventBus)
local Builder = require(script.Parent.Parent.World.Builder)
local Chapter4Map = require(script.Parent.Parent.World.Chapter4Map)

local Chapter4 = {
	id = 4,
	title = "The Hollow",
	config = GameConfig.Chapter4,
	thunder = false,
}

local CH = GameConfig.Chapter4

local WAKE_LINES = {
	Driver = "\"Kids? Is everyone here? I'm so sorry. I followed a voice off the road...\"",
	Ranger = "\"You came back for me. After everything at the camp. Thank you.\"",
	Pilot = "\"I was flying you to the hospital, and then... I don't remember landing.\"",
}

function Chapter4.buildMap()
	return Chapter4Map.Build()
end

function Chapter4.spawns(refs)
	return refs.Spawns
end

function Chapter4.applyLighting()
	-- Last light of evening, warm and readable, with long shadows under the pines.
	Lighting.ClockTime = 18.2
	Lighting.Brightness = 2
	Lighting.Ambient = Color3.fromRGB(78, 70, 74)
	Lighting.OutdoorAmbient = Color3.fromRGB(118, 104, 110)
	Lighting.EnvironmentDiffuseScale = 0.45
	Lighting.EnvironmentSpecularScale = 0.3
	Lighting.GlobalShadows = true
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
	atmosphere.Density = 0.3
	atmosphere.Offset = 0.1
	atmosphere.Color = Color3.fromRGB(200, 160, 150)
	atmosphere.Decay = Color3.fromRGB(110, 80, 90)
	atmosphere.Glare = 0.2
	atmosphere.Haze = 1.4
	atmosphere.Parent = Lighting
	local grade = Lighting:FindFirstChild("StormGrade") or Instance.new("ColorCorrectionEffect")
	grade.Name = "StormGrade"
	grade.Saturation = -0.15
	grade.Contrast = 0.05
	grade.Brightness = 0.03
	grade.TintColor = Color3.fromRGB(255, 236, 225)
	grade.Parent = Lighting
end

-- A little flame floats above whoever is carrying one, so the team can see it.
local function setFlame(player: Player, lostId: string?)
	player:SetAttribute("Flame", lostId)
	local head = player.Character and player.Character:FindFirstChild("Head")
	local existing = head and head:FindFirstChild("FlameMarker")
	if existing then
		existing:Destroy()
	end
	if lostId and head then
		local billboard = Instance.new("BillboardGui")
		billboard.Name = "FlameMarker"
		billboard.Size = UDim2.fromOffset(40, 40)
		billboard.StudsOffset = Vector3.new(0, 2.4, 0)
		billboard.LightInfluence = 0
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.TextScaled = true
		label.Text = "🔥"
		label.Parent = billboard
		billboard.Parent = head
	end
end

----------------------------------------------------------------------------
-- Beats

local function beatShore(story)
	local refs = story.refs
	story.services.EquipmentService:EnableLoadouts()
	story.notePrompt(refs.FerrymanNote, "A note on the dock", "Last stop. I don't go further than this shore.\n\nThe ones you are looking for are in the old groves. They aren't dead. They're asleep, the way trees sleep.\n\nWarm light wakes them. Take their flames to the stone fires around the big tree.\n\nI'll wait for you. Don't be long.")
	story.caption("The ferry bumps against an old dock. The ferryman points into the trees and won't look at you.")
	story.setObjective("Go to the lit cabin by the shore", refs.CabinDoor)
	story.waitUntil(function()
		return story.anyPlayerWithin(refs.CabinDoor, 20) ~= nil
	end)
end

local function beatCabin(story)
	local refs, services = story.refs, story.services
	story.addSafeZone(refs.CabinSafeZone)
	story.setCheckpoint(refs.CabinCheckpoint)
	story.setObjective("Read the journal on the table", refs.Journal.Position)
	local reader = story.waitForPrompt(refs.Journal, "Read", "Old journal", 0.6)
	story.openNote(reader, "Ranger Hale's first journal", "Year one. There is a tree at the heart of Hollow Pines older than anything. The old folks call it the Hollow One.\n\nIt is lonely. When someone gets lost, it keeps them, to have company. The tall thing at the tree line, the voices, the copies: they are all just it, looking.\n\nIt took the bus driver. It took a pilot. One day it will take me.\n\nWarm light wakes the ones it keeps. And if you light the three stone fires around it, it remembers it's only a tree, and lets everyone go.")
	story.caption(reader.DisplayName .. " read Hale's journal. The lost are asleep in the groves. Warm light wakes them.")
	services.OnboardingService:HintAll("Wake")

	local watcher = services.CreatureService.watcher
	watcher:Reveal(CFrame.lookAt(refs.Junction + Vector3.new(-30, 0, 20), refs.CabinDoor))
	story.caption("Something tall is standing at the fork in the path. Watching. It knows why you're here.")
	task.delay(5, function()
		if watcher.mode == "Reveal" then
			watcher:SetMode("Stalk")
		end
	end)
end

local function beatLightTheWay(story)
	local refs, services = story.refs, story.services
	local hollow = services.CreatureService.hollow
	local freed, lit = 0, 0
	local function update()
		local target = nil
		for _, lost in refs.Lost do
			if not lost.freed then
				target = lost.position
				break
			end
		end
		story.setObjective(string.format("Wake the lost (%d/%d) and light the stone fires (%d/%d)", freed, CH.LostCount, lit, #refs.Braziers), target or refs.HollowCenter)
	end
	update()

	for _, lost in refs.Lost do
		local prompt = Builder.prompt(lost.statue.PrimaryPart, "Wake", lost.name, 3)
		prompt.Triggered:Connect(function(player)
			if lost.freed then
				return
			end
			if not services.EquipmentService:HasLight(player) then
				Net.Event("Toast"):FireClient(player, "It needs warm light. Hold your light and switch it on (F).", "Warning")
				return
			end
			if player:GetAttribute("Flame") then
				Net.Event("Toast"):FireClient(player, "You're already carrying a flame. Take it to a stone fire first.", "Warning")
				return
			end
			lost.freed = true
			freed += 1
			prompt:Destroy()
			local color = lost.statue.PrimaryPart:GetAttribute("TrueColor")
			for _, piece in lost.statue:GetDescendants() do
				if piece:IsA("BasePart") then
					if piece.Name == "Vine" then
						piece:Destroy()
					elseif piece.Name == "Body" and color then
						piece.Color = color
						piece.Material = Enum.Material.Fabric
					elseif piece.Name == "Head" then
						piece.Color = Color3.fromRGB(234, 184, 146)
						piece.Material = Enum.Material.SmoothPlastic
					end
				end
			end
			story.effect("Wake", { soundId = Assets.Sounds.Wake })
			story.caption(string.format("%s wakes up! %s", lost.name, WAKE_LINES[lost.id] or ""), "Story")
			story.caption(string.format("%s gives %s a small, warm flame and heads for the ferry.", lost.name, player.DisplayName))
			setFlame(player, lost.id)
			EventBus.Fire("LostFreed", player)
			task.delay(6, function()
				lost.statue:Destroy()
			end)
			update()
		end)
	end

	for _, brazier in refs.Braziers do
		local prompt = Builder.prompt(brazier.part, "Light", "Stone fire", 1)
		prompt.Triggered:Connect(function(player)
			if brazier.lit then
				return
			end
			if not player:GetAttribute("Flame") then
				Net.Event("Toast"):FireClient(player, "You need a flame from one of the lost to light this.", "Warning")
				return
			end
			brazier.lit = true
			lit += 1
			prompt:Destroy()
			setFlame(player, nil)
			brazier.fire.Transparency = 0.1
			brazier.light.Enabled = true
			story.effect("Brazier", { soundId = Assets.Sounds.Brazier })
			story.caption(string.format("%s lit a stone fire. (%d/%d)", player.DisplayName, lit, #refs.Braziers))
			EventBus.Fire("BrazierLit", player)
			update()
		end)
	end

	-- It opens its eye the first time someone steps into the clearing.
	story.waitUntil(function()
		return story.anyPlayerWithin(refs.HollowCenter, 135) ~= nil or lit > 0
	end)
	hollow:SetMode("Awake")
	story.effect("GazeSting", { soundId = Assets.Sounds.WatcherSting })
	story.caption("In the middle of the clearing, a giant hollow pine opens one glowing eye.")
	services.OnboardingService:HintAll("Gaze")

	story.waitUntil(function()
		return lit >= #refs.Braziers
	end)
end

local function beatHome(story)
	local refs, services = story.refs, story.services
	local hollow = services.CreatureService.hollow
	local watcher = services.CreatureService.watcher

	hollow:SetMode("Dormant")
	story.effect("Remember", {})
	local lines = {
		"The three fires burn bright. The Hollow One's eye fills with their light.",
		"For a moment it looks less like a monster and more like a very old, very tired tree.",
		"The ground shakes. Roots let go all through the forest. It remembers.",
	}
	for _, line in lines do
		story.caption(line, "Story")
		task.wait(3.5)
	end
	-- One piece of it hasn't let go yet.
	story.caption("But the tall thing at the tree line doesn't want you to leave. It's coming. RUN for the ferry!", "Mimic")
	hollow:SetMode("Angry")
	local function release()
		watcher:Reveal(CFrame.lookAt(refs.HollowEdge + Vector3.new(0, 0, 30), refs.Junction))
		watcher:SetMode("Chase")
	end
	release()
	story.effect("ChaseStart", { soundId = Assets.Sounds.ChaseMusic })
	story.setObjective("RUN back to the ferry!", refs.Dock)
	story.setCheckpoint(refs.CabinCheckpoint)
	services.OnboardingService:HintAll("Sprint")

	-- Once everyone is clear of the clearing its gaze closes for good.
	task.spawn(function()
		while hollow.mode == "Angry" do
			task.wait(1)
			if not story.anyPlayerWithin(refs.HollowCenter, 140) then
				hollow:SetMode("Dormant")
			end
		end
	end)

	story.runEscape({
		exitZone = refs.ExitZone,
		exitHold = refs.ExitHold,
		escapedText = "%s made it back to the ferry!",
		creature = watcher,
		restart = release,
		speedUpAfter = 90,
	})
	hollow:SetMode("Dormant")
end

function Chapter4.run(story)
	local onboarding = story.services.OnboardingService
	onboarding:Step(1, "Arrived")
	story.intro({ length = CH.IntroLength })
	onboarding:Step(2, "IntroWatched")
	beatShore(story)
	onboarding:Step(3, "ReachedCabin")
	beatCabin(story)
	onboarding:Step(4, "JournalRead")
	beatLightTheWay(story)
	onboarding:Step(5, "FiresLit")
	beatHome(story)
	onboarding:Step(6, "Escaped")
	for _, player in Players:GetPlayers() do
		setFlame(player, nil)
	end
end

function Chapter4.ending(_story)
	return {
		scene = "Home",
		text = "Two days later. Hollow Pines Middle School.\nMr. Dorsey, Ranger Hale and Captain Reyes are home. The reserve is closed for good, and the forest has gone quiet.\n\nBut look at the bottom of the photo. Someone brought home a tiny pine seedling.\nNobody remembers picking it up.\n\nTHE END. Thank you for playing The Hollow Pines.",
	}
end

return Chapter4
