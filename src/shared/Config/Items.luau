-- Catalogue of everything a player can own. Equipment is earned through levels;
-- cosmetics and pets are bought with Embers (earnable in play, or purchasable).
-- Nothing sold for Robux affects survival odds: see docs/MONETIZATION.md.

local Items = {}

Items.Equipment = {
	Flashlight = {
		id = "Flashlight",
		name = "Flashlight",
		description = "A dented flashlight. The battery will not last forever.",
		slot = "Light",
		unlockLevel = 1,
		battery = 180, -- seconds of light
		range = 45,
		brightness = 3,
	},
	Lantern = {
		id = "Lantern",
		name = "Storm Lantern",
		description = "Lights everyone around you. Calms nearby teammates.",
		slot = "Light",
		unlockLevel = 4,
		battery = 240,
		range = 22,
		brightness = 2,
		teamCalm = 1.0, -- extra fear recovery for teammates in range
	},
	Walkie = {
		id = "Walkie",
		name = "Walkie-Talkie",
		description = "Ping your location to the whole team.",
		slot = "Tool",
		unlockLevel = 2,
		cooldown = 20,
	},
	Camera = {
		id = "Camera",
		name = "Instant Camera",
		description = "The flash makes The Watcher look away. Photos reveal hidden clues.",
		slot = "Tool",
		unlockLevel = 6,
		cooldown = 30,
		stunTime = 4,
	},
	CalmTonic = {
		id = "CalmTonic",
		name = "Chamomile Flask",
		description = "A warm drink that lowers fear. One use per chapter.",
		slot = "Tool",
		unlockLevel = 3,
		fearReduction = 40,
	},
	Whistle = {
		id = "Whistle",
		name = "Ranger's Whistle",
		description = "Blow it to lure The Ranger to where you stand. Found in Chapter 2.",
		slot = "Story", -- handed out by the story, never equipped from the menu
		storyItem = true,
		unlockLevel = 0,
		cooldown = 12,
	},
}

Items.DefaultLoadout = { Light = "Flashlight", Tool = "Walkie" }

Items.Cosmetics = {
	FlashlightBeamWarm = { id = "FlashlightBeamWarm", name = "Warm Beam", kind = "BeamColor", color = Color3.fromRGB(255, 214, 160), price = 0 },
	FlashlightBeamMint = { id = "FlashlightBeamMint", name = "Mint Beam", kind = "BeamColor", color = Color3.fromRGB(170, 255, 214), price = 300 },
	FlashlightBeamViolet = { id = "FlashlightBeamViolet", name = "Violet Beam", kind = "BeamColor", color = Color3.fromRGB(200, 170, 255), price = 450 },
	FlashlightBeamGold = { id = "FlashlightBeamGold", name = "Golden Beam", kind = "BeamColor", color = Color3.fromRGB(255, 200, 80), price = 0, vipOnly = true },
	TitleSurvivor = { id = "TitleSurvivor", name = "Survivor", kind = "Title", price = 0, achievement = "SurviveTheStorm" },
	TitleDetective = { id = "TitleDetective", name = "Detective", kind = "Title", price = 600 },
	TitleNightOwl = { id = "TitleNightOwl", name = "Night Owl", kind = "Title", price = 0, achievement = "Level10" },
}

Items.Pets = {
	Firefly = {
		id = "Firefly",
		name = "Firefly",
		description = "A tiny glowing friend.",
		price = 400,
		color = Color3.fromRGB(255, 240, 120),
		size = 0.4,
		glow = 6,
	},
	Owlet = {
		id = "Owlet",
		name = "Owlet",
		description = "Hoots softly. Very judgemental.",
		price = 900,
		color = Color3.fromRGB(150, 120, 90),
		size = 1.0,
		glow = 0,
	},
	LanternFox = {
		id = "LanternFox",
		name = "Lantern Fox",
		description = "Carries a little lantern on its tail.",
		price = 1600,
		color = Color3.fromRGB(230, 120, 60),
		size = 1.3,
		glow = 8,
	},
	GhostPup = {
		id = "GhostPup",
		name = "Ghost Pup",
		description = "VIP exclusive. Friendly, mostly see-through.",
		price = 0,
		vipOnly = true,
		color = Color3.fromRGB(200, 230, 255),
		size = 1.1,
		glow = 4,
	},
}

function Items.Find(itemId: string)
	return Items.Equipment[itemId] or Items.Cosmetics[itemId] or Items.Pets[itemId]
end

function Items.Category(itemId: string): string?
	if Items.Equipment[itemId] then
		return "Equipment"
	elseif Items.Cosmetics[itemId] then
		return "Cosmetics"
	elseif Items.Pets[itemId] then
		return "Pets"
	end
	return nil
end

return Items
