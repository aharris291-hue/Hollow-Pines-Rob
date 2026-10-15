-- The menu window: Shop, Loadout, Quests, Achievements and Settings tabs.
-- Every tab redraws from the profile, so it is always in sync with the server.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Items = require(Shared.Config.Items)
local Monetization = require(Shared.Config.Monetization)
local Quests = require(Shared.Config.Quests)
local Achievements = require(Shared.Config.Achievements)
local QuestLogic = require(Shared.Util.QuestLogic)
local Progression = require(Shared.Util.Progression)
local Net = require(Shared.Util.Net)
local UIKit = require(script.Parent.UIKit)

local Menus = {}
Menus.__index = Menus

local Theme = UIKit.Theme
local TABS = { "Shop", "Loadout", "Quests", "Awards", "Settings" }

local function sortedKeys(t, by)
	local keys = {}
	for key in t do
		table.insert(keys, key)
	end
	table.sort(keys, function(a, b)
		return by(t[a]) < by(t[b])
	end)
	return keys
end

function Menus.new(gui: ScreenGui, controllers)
	local self = setmetatable({}, Menus)
	self.controllers = controllers
	self.current = nil

	local bar = UIKit.new("Frame", { Name = "MenuButtons", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 52), Size = UDim2.fromOffset(0, 32), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, Parent = gui }, { UIKit.list(Enum.FillDirection.Horizontal, 6) })
	for index, tab in TABS do
		UIKit.button(tab, { Size = UDim2.fromOffset(78, 32), TextSize = 14, LayoutOrder = index, Parent = bar }, function()
			self:Toggle(tab)
		end)
	end

	self.window = UIKit.panel({ Name = "Menu", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.52), Size = UDim2.new(0.6, 0, 0.7, 0), Visible = false, Parent = gui })
	UIKit.new("UISizeConstraint", { MinSize = Vector2.new(320, 300), MaxSize = Vector2.new(760, 620), Parent = self.window })
	UIKit.padding(14).Parent = self.window
	self.title = UIKit.text({ Size = UDim2.new(1, -50, 0, 30), Font = Theme.FontBold, TextSize = 24, Parent = self.window })
	UIKit.button("✕", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.fromOffset(34, 34), Parent = self.window }, function()
		self:Close()
	end)
	self.body = UIKit.new("ScrollingFrame", {
		Position = UDim2.fromOffset(0, 42),
		Size = UDim2.new(1, 0, 1, -42),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = self.window,
	}, { UIKit.list(nil, 8) })

	controllers.DataController.Changed:Connect(function()
		if self.current then
			self:_render()
		end
	end)
	return self
end

function Menus:Toggle(tab: string)
	if self.current == tab then
		self:Close()
	else
		self.current = tab
		self.window.Visible = true
		self:_render()
	end
end

function Menus:Close()
	self.current = nil
	self.window.Visible = false
end

function Menus:_render()
	local profile = self.controllers.DataController.Profile
	UIKit.clear(self.body)
	self.title.Text = self.current
	if not profile then
		UIKit.text({ Text = "Loading your save...", Parent = self.body })
		return
	end
	local builder = self["_" .. self.current]
	builder(self, profile)
end

-- One row: title + subtitle on the left, an optional button on the right.
function Menus:_row(order: number, title: string, subtitle: string?, buttonText: string?, onClick: (() -> ())?, highlight: boolean?)
	local row = UIKit.panel({ Size = UDim2.new(1, -8, 0, 58), BackgroundColor3 = if highlight then Color3.fromRGB(44, 40, 30) else Theme.PanelLight, LayoutOrder = order, Parent = self.body })
	UIKit.padding(8).Parent = row
	UIKit.text({ Size = UDim2.new(1, -130, 0, 20), Font = Theme.FontBold, Text = title, Parent = row })
	if subtitle then
		UIKit.text({ Position = UDim2.fromOffset(0, 22), Size = UDim2.new(1, -130, 0, 18), TextSize = 13, TextColor3 = Theme.Muted, Text = subtitle, TextTruncate = Enum.TextTruncate.AtEnd, Parent = row })
	end
	if buttonText then
		local button = UIKit.button(buttonText, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(118, 34), TextSize = 14, Parent = row }, onClick or function() end)
		button.Active = onClick ~= nil
		button.AutoButtonColor = false
		if not onClick then
			button.TextColor3 = Theme.Muted
		end
	end
	return row
end

function Menus:_header(order: number, text: string)
	UIKit.text({ Text = text, Font = Theme.FontBold, TextSize = 18, TextColor3 = Theme.Accent, LayoutOrder = order, Parent = self.body })
end

function Menus:_Shop(profile)
	local order = 0
	local function nextOrder()
		order += 1
		return order
	end

	self:_header(nextOrder(), "Spend Embers  (you have 🔥 " .. profile.Embers .. ")")
	local forSale = {}
	for id, item in Items.Cosmetics do
		if (item.price or 0) > 0 then
			forSale[id] = item
		end
	end
	for id, item in Items.Pets do
		if (item.price or 0) > 0 then
			forSale[id] = item
		end
	end
	for _, id in sortedKeys(forSale, function(item)
		return item.price
	end) do
		local item = forSale[id]
		local owned = profile.Owned[id]
		local label = if owned then "Owned" else "🔥 " .. item.price
		self:_row(nextOrder(), item.name, item.description or (if item.kind == "BeamColor" then "Flashlight beam colour" else item.kind), label, if owned then nil else function()
			Net.Event("BuyItem"):FireServer(id)
		end, owned)
	end

	local robuxOffers = {}
	for key, pass in Monetization.GamePasses do
		if pass.id ~= 0 then
			table.insert(robuxOffers, { name = pass.name, text = pass.description, prompt = function()
				MarketplaceService:PromptGamePassPurchase(Players.LocalPlayer, pass.id)
			end, owned = (key == "VIP" and profile.IsVIP) })
		end
	end
	for _, product in Monetization.Products do
		if product.id ~= 0 then
			local text = if product.embers then "+" .. product.embers .. " Embers" else "Get back up once, without waiting"
			table.insert(robuxOffers, { name = product.name, text = text, prompt = function()
				MarketplaceService:PromptProductPurchase(Players.LocalPlayer, product.id)
			end })
		end
	end
	if #robuxOffers > 0 then
		self:_header(nextOrder(), "Support the game")
		for _, offer in robuxOffers do
			self:_row(nextOrder(), offer.name, offer.text, if offer.owned then "Owned" else "Buy", if offer.owned then nil else offer.prompt, offer.owned)
		end
	end
end

function Menus:_Loadout(profile)
	local order = 0
	local function nextOrder()
		order += 1
		return order
	end

	self:_header(nextOrder(), "Equipment")
	for _, id in sortedKeys(Items.Equipment, function(item)
		return item.unlockLevel
	end) do
		local item = Items.Equipment[id]
		local owned = profile.Owned[id]
		local equipped = profile.Loadout[item.slot] == id
		local button = if equipped then "Equipped" elseif owned then "Equip" else "Level " .. item.unlockLevel
		self:_row(nextOrder(), item.name .. "  (" .. item.slot .. " slot)", item.description, button, if owned and not equipped then function()
			Net.Event("EquipItem"):FireServer(id)
		end else nil, equipped)
	end

	self:_header(nextOrder(), "Beams & titles")
	for _, id in sortedKeys(Items.Cosmetics, function(item)
		return item.name
	end) do
		local item = Items.Cosmetics[id]
		if profile.Owned[id] then
			local equipped = profile.EquippedBeam == id or profile.EquippedTitle == id
			local button = if equipped and item.kind == "Title" then "Remove" elseif equipped then "Equipped" else "Equip"
			self:_row(nextOrder(), item.name, if item.kind == "Title" then "Title" else "Beam colour", button, if equipped and item.kind ~= "Title" then nil else function()
				Net.Event("EquipItem"):FireServer(id)
			end, equipped)
		end
	end

	self:_header(nextOrder(), "Pets")
	local anyPet = false
	for id, item in Items.Pets do
		if profile.Owned[id] then
			anyPet = true
			local equipped = profile.EquippedPet == id
			self:_row(nextOrder(), item.name, item.description, if equipped then "Put away" else "Bring along", function()
				Net.Event("EquipItem"):FireServer(if equipped then "" else id)
			end, equipped)
		end
	end
	if not anyPet then
		UIKit.text({ Text = "No pets yet. Find them in the Shop.", TextColor3 = Theme.Muted, LayoutOrder = nextOrder(), Parent = self.body })
	end
end

function Menus:_Quests(profile)
	local order = 0
	self:_header(0, string.format("Level %d  ·  %d / %d XP", profile.Level, profile.XP, Progression.xpToNext(profile.Level)))
	for questId, state in profile.Quests.Active do
		local quest = QuestLogic.findQuest(Quests.Pool, questId)
		if quest then
			order += 1
			local complete = state.progress >= quest.goal
			local button = if state.claimed then "Claimed" elseif complete then "Claim" else string.format("%d / %d", state.progress, quest.goal)
			self:_row(order, quest.text, string.format("Reward: 🔥 %d  ·  %d XP", quest.embers, quest.xp), button, if complete and not state.claimed then function()
				Net.Event("ClaimQuest"):FireServer(questId)
			end else nil, complete and not state.claimed)
		end
	end
	UIKit.text({ Text = "New quests every day at midnight UTC.", TextColor3 = Theme.Muted, TextSize = 13, LayoutOrder = 99, Parent = self.body })
end

function Menus:_Awards(profile)
	for index, achievement in Achievements do
		local unlocked = profile.Achievements[achievement.id] ~= nil
		local progress = math.min(profile.Stats[achievement.stat] or 0, achievement.goal)
		self:_row(index, (if unlocked then "🏆 " else "🔒 ") .. achievement.name, achievement.text, if unlocked then "Unlocked" else string.format("%d / %d", progress, achievement.goal), nil, unlocked)
	end
end

local SETTINGS = {
	{ key = "Captions", label = "Sound captions", hint = "Describe important sounds on screen" },
	{ key = "ReducedFlashing", label = "Reduce flashing", hint = "Lightning and camera flashes become gentle dims" },
	{ key = "ReducedShake", label = "Reduce camera shake", hint = "No screen shaking" },
	{ key = "CalmerScares", label = "Calmer scares", hint = "Fear rises half as fast and effects are softer" },
	{ key = "ColorblindMarkers", label = "Colourblind markers", hint = "Objective marker uses shape and white" },
	{ key = "TextScale", label = "Interface size", hint = "Make text and menus bigger", step = 0.1, min = 1, max = 1.5 },
	{ key = "MusicVolume", label = "Music volume", step = 0.1, min = 0, max = 1 },
	{ key = "EffectsVolume", label = "Effects volume", step = 0.1, min = 0, max = 1 },
}

function Menus:_Settings(profile)
	for index, setting in SETTINGS do
		local value = profile.Settings[setting.key]
		if type(value) == "boolean" then
			self:_row(index, setting.label, setting.hint, if value then "On" else "Off", function()
				Net.Event("ChangeSetting"):FireServer(setting.key, not value)
			end, value)
		else
			local row = self:_row(index, setting.label, setting.hint or string.format("%d%%", math.floor(value * 100 + 0.5)))
			local function change(delta)
				local nextValue = math.clamp(math.floor((value + delta) * 10 + 0.5) / 10, setting.min, setting.max)
				Net.Event("ChangeSetting"):FireServer(setting.key, nextValue)
			end
			UIKit.button("−", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -84, 0.5, 0), Size = UDim2.fromOffset(34, 34), Parent = row }, function()
				change(-setting.step)
			end)
			UIKit.text({ AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -40, 0.5, 0), Size = UDim2.fromOffset(44, 20), TextXAlignment = Enum.TextXAlignment.Center, Text = string.format("%.1f", value), Parent = row })
			UIKit.button("+", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(34, 34), Parent = row }, function()
				change(setting.step)
			end)
		end
	end
end

return Menus
