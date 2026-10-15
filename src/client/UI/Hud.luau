-- In-game HUD: fear, stamina and battery bars, objective + world marker,
-- captions, toasts, the team list and the Embers/level badge.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local UIKit = require(script.Parent.UIKit)

local Hud = {}
Hud.__index = Hud

local Theme = UIKit.Theme
local player = Players.LocalPlayer

local TIER_COLORS = {
	Calm = Color3.fromRGB(110, 190, 255),
	Uneasy = Color3.fromRGB(240, 210, 110),
	Scared = Color3.fromRGB(245, 150, 80),
	Panicked = Color3.fromRGB(235, 80, 80),
}

local TOAST_COLORS = {
	Success = Theme.Success,
	Warning = Theme.Accent,
	Error = Theme.Danger,
	Achievement = Color3.fromRGB(220, 170, 255),
	Quest = Color3.fromRGB(140, 220, 200),
	LevelUp = Color3.fromRGB(255, 220, 120),
	Info = Theme.Text,
}

function Hud.new(gui: ScreenGui, controllers)
	local self = setmetatable({}, Hud)
	self.controllers = controllers
	self.isChapter = ReplicatedStorage:GetAttribute("PlaceRole") ~= "Lobby"

	-- Status (top left)
	local status = UIKit.panel({ Name = "Status", Size = UDim2.fromOffset(230, 0), AutomaticSize = Enum.AutomaticSize.Y, Position = UDim2.fromOffset(12, 12), Parent = gui })
	UIKit.padding(10).Parent = status
	UIKit.list(nil, 6).Parent = status
	self.fearLabel = UIKit.text({ Text = "Calm", Font = Theme.FontBold, TextSize = 14, LayoutOrder = 1, Parent = status })
	self.fearBar, self.fearFill = UIKit.bar({ Size = UDim2.new(1, 0, 0, 12), Color = TIER_COLORS.Calm, LayoutOrder = 2, Parent = status })
	self.staminaBar, self.staminaFill, self.staminaLabel = UIKit.bar({ Size = UDim2.new(1, 0, 0, 10), Color = Color3.fromRGB(150, 220, 140), LayoutOrder = 3, Parent = status })
	self.batteryBar, self.batteryFill, self.batteryLabel = UIKit.bar({ Size = UDim2.new(1, 0, 0, 14), Color = Color3.fromRGB(255, 230, 150), LayoutOrder = 5, Text = "Battery", Parent = status })
	self.teamList = UIKit.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 6, Parent = status }, { UIKit.list(nil, 2) })
	-- Chapter 2+: how loud you are, and whether you're hidden from The Ranger.
	self.noiseLabel = UIKit.text({ Size = UDim2.new(1, 0, 0, 16), TextSize = 13, Font = Theme.FontBold, LayoutOrder = 4, Visible = false, Parent = status })
	status.Visible = self.isChapter

	-- Objective (top centre)
	self.objective = UIKit.panel({ Name = "Objective", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 12), Size = UDim2.fromOffset(440, 0), AutomaticSize = Enum.AutomaticSize.Y, Visible = false, Parent = gui })
	UIKit.padding(10).Parent = self.objective
	self.objectiveText = UIKit.text({ Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextXAlignment = Enum.TextXAlignment.Center, Font = Theme.Story, TextSize = 18, Parent = self.objective })

	-- Embers + level (top right, left of the menu buttons)
	self.wallet = UIKit.panel({ Name = "Wallet", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 12), Size = UDim2.fromOffset(200, 34), Parent = gui })
	self.walletText = UIKit.text({ Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center, Font = Theme.FontBold, Text = "…", Parent = self.wallet })

	-- Captions (bottom centre)
	self.captions = UIKit.new("Frame", { Name = "Captions", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -110), Size = UDim2.fromOffset(640, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = gui }, { UIKit.list(nil, 4, Enum.HorizontalAlignment.Center) })

	-- Toasts (right)
	self.toasts = UIKit.new("Frame", { Name = "Toasts", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 100), Size = UDim2.fromOffset(300, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = gui }, { UIKit.list(nil, 6, Enum.HorizontalAlignment.Right) })

	-- First-time hint card, under the objective (clear of chat and mobile controls).
	self.hint = UIKit.panel({ Name = "Hint", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 84), Size = UDim2.fromOffset(320, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = Color3.fromRGB(28, 36, 48), Visible = false, Parent = gui })
	UIKit.padding(12).Parent = self.hint
	UIKit.list(nil, 4).Parent = self.hint
	UIKit.text({ Text = "TIP", Font = Theme.FontBold, TextSize = 13, TextColor3 = Theme.Calm, LayoutOrder = 1, Parent = self.hint })
	self.hintText = UIKit.text({ Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextSize = 16, LayoutOrder = 2, Parent = self.hint })
	self.hintQueue = {}

	self:_buildMarker()
	RunService.Heartbeat:Connect(function()
		self:_tick()
	end)
	controllers.DataController:Observe(function(profile)
		self:_onProfile(profile)
	end)
	return self
end

function Hud:_buildMarker()
	local anchor = Instance.new("Part")
	anchor.Name = "ObjectiveMarker"
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = Vector3.one
	local billboard = Instance.new("BillboardGui")
	billboard.AlwaysOnTop = true
	billboard.Size = UDim2.fromOffset(120, 54)
	billboard.LightInfluence = 0
	billboard.MaxDistance = 2000
	billboard.Enabled = false
	billboard.Parent = anchor
	self.markerIcon = UIKit.text({ Size = UDim2.new(1, 0, 0, 30), TextXAlignment = Enum.TextXAlignment.Center, Font = Theme.FontBold, TextSize = 28, Text = "◆", TextColor3 = Theme.Accent, TextStrokeTransparency = 0.3, Parent = billboard })
	self.markerDistance = UIKit.text({ Position = UDim2.fromOffset(0, 30), Size = UDim2.new(1, 0, 0, 20), TextXAlignment = Enum.TextXAlignment.Center, Font = Theme.FontBold, TextSize = 14, TextStrokeTransparency = 0.3, Parent = billboard })
	anchor.Parent = workspace.CurrentCamera
	self.markerAnchor = anchor
	self.markerGui = billboard
end

function Hud:SetObjective(text: string, marker: Vector3?)
	self.objective.Visible = text ~= ""
	self.objectiveText.Text = text
	self.markerPosition = marker
	self.markerGui.Enabled = marker ~= nil
	if marker then
		self.markerAnchor.Position = marker + Vector3.new(0, 6, 0)
	end
end

function Hud:Caption(text: string, kind: string?)
	local color = if kind == "Mimic" then Color3.fromRGB(200, 170, 255) elseif kind == "Radio" then Color3.fromRGB(170, 230, 200) elseif kind == "Hint" then Color3.fromRGB(255, 220, 130) else Theme.Text
	local label = UIKit.text({
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		TextXAlignment = Enum.TextXAlignment.Center,
		Font = if kind == "Sound" then Theme.Font else Theme.Story,
		TextSize = 20,
		TextColor3 = color,
		TextStrokeTransparency = 0.35,
		Text = text,
		Parent = self.captions,
	})
	local children = {}
	for _, child in self.captions:GetChildren() do
		if child:IsA("TextLabel") then
			table.insert(children, child)
		end
	end
	if #children > 3 then
		children[1]:Destroy()
	end
	task.delay(6, function()
		if label.Parent then
			UIKit.tween(label, 0.6, { TextTransparency = 1, TextStrokeTransparency = 1 })
			task.wait(0.6)
			label:Destroy()
		end
	end)
end

-- Hints queue up so two arriving together are both read.
function Hud:Hint(text: string)
	table.insert(self.hintQueue, text)
	if self.hintShowing then
		return
	end
	self.hintShowing = true
	task.spawn(function()
		while #self.hintQueue > 0 do
			self.hintText.Text = table.remove(self.hintQueue, 1)
			self.hint.Visible = true
			task.wait(7)
			self.hint.Visible = false
			task.wait(0.4)
		end
		self.hintShowing = false
	end)
end

function Hud:Toast(text: string, kind: string?)
	local toast = UIKit.panel({ Size = UDim2.fromOffset(300, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = self.toasts })
	UIKit.padding(10).Parent = toast
	UIKit.text({ Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Text = text, TextColor3 = TOAST_COLORS[kind or "Info"] or Theme.Text, Font = Theme.FontBold, Parent = toast })
	task.delay(4, function()
		if toast.Parent then
			UIKit.tween(toast, 0.4, { BackgroundTransparency = 1 })
			task.wait(0.4)
			toast:Destroy()
		end
	end)
end

function Hud:_onProfile(profile)
	self.walletText.Text = string.format("🔥 %d   ·   Lv %d", profile.Embers, profile.Level)
	local colorblind = profile.Settings.ColorblindMarkers
	-- Colourblind markers use shape and a high-contrast white instead of hue alone.
	self.markerIcon.Text = if colorblind then "▼ GO" else "◆"
	self.markerIcon.TextColor3 = if colorblind then Color3.new(1, 1, 1) else Theme.Accent
end

function Hud:_tick()
	if not self.isChapter then
		return
	end
	local fear = player:GetAttribute("Fear") or 0
	local tier = player:GetAttribute("FearTier") or "Calm"
	self.fearFill.Size = UDim2.fromScale(fear / 100, 1)
	self.fearFill.BackgroundColor3 = TIER_COLORS[tier] or TIER_COLORS.Calm
	self.fearLabel.Text = "Fear: " .. tier
	self.staminaFill.Size = UDim2.fromScale((player:GetAttribute("Stamina") or 100) / 100, 1)

	local listening = (ReplicatedStorage:GetAttribute("Chapter") or 1) >= 2
	self.noiseLabel.Visible = listening
	if listening then
		local noise = player:GetAttribute("Noise") or 0
		if player:GetAttribute("Hidden") then
			self.noiseLabel.Text = "Hidden"
			self.noiseLabel.TextColor3 = Color3.fromRGB(150, 220, 140)
		else
			self.noiseLabel.Text = if noise >= 2 then "Noise: LOUD" elseif noise == 1 then "Noise: some" else "Noise: quiet"
			self.noiseLabel.TextColor3 = if noise >= 2 then Theme.Danger elseif noise == 1 then Color3.fromRGB(255, 210, 120) else Theme.Muted
		end
	end

	local character = player.Character
	local tool = character and character:FindFirstChildOfClass("Tool")
	local battery = tool and tool:GetAttribute("Battery")
	self.batteryBar.Visible = battery ~= nil
	if battery then
		local max = tool:GetAttribute("MaxBattery") or 1
		self.batteryFill.Size = UDim2.fromScale(battery / max, 1)
		self.batteryLabel.Text = if tool:GetAttribute("On") then "Light on (F)" else "Light off (F)"
	end

	if self.markerPosition and character and character:FindFirstChild("HumanoidRootPart") then
		local distance = (character.HumanoidRootPart.Position - self.markerPosition).Magnitude
		self.markerDistance.Text = string.format("%dm", math.floor(distance / 3.57))
	end

	-- Team list refreshes a few times a second.
	self.teamTimer = (self.teamTimer or 0) + 1
	if self.teamTimer % 15 == 0 then
		UIKit.clear(self.teamList)
		for _, other in Players:GetPlayers() do
			if other ~= player then
				local otherTier = other:GetAttribute("FearTier") or "Calm"
				local stateText = if other:GetAttribute("Downed") then "CAUGHT" elseif other:GetAttribute("Escaped") then "safe" else otherTier
				UIKit.text({
					Size = UDim2.new(1, 0, 0, 16),
					TextSize = 13,
					Text = other.DisplayName .. "  ·  " .. stateText,
					TextColor3 = if other:GetAttribute("Downed") then Theme.Danger else (TIER_COLORS[otherTier] or Theme.Text),
					Parent = self.teamList,
				})
			end
		end
	end
end

return Hud
