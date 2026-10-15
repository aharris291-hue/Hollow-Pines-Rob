-- Modal panels: notes, the radio dial, the "caught" overlay, chapter results and
-- the lobby chapter select.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Monetization = require(Shared.Config.Monetization)
local Chapters = require(Shared.Config.Chapters)
local ChapterUnlock = require(Shared.Util.ChapterUnlock)
local Net = require(Shared.Util.Net)
local UIKit = require(script.Parent.UIKit)

local Panels = {}
Panels.__index = Panels

local Theme = UIKit.Theme

function Panels.new(gui: ScreenGui, controllers)
	local self = setmetatable({}, Panels)
	self.gui = gui
	self.controllers = controllers
	self.modal = nil
	return self
end

function Panels:Close()
	if self.modal then
		self.modal:Destroy()
		self.modal = nil
	end
end

function Panels:_modal(width: number, height: number): Frame
	self:Close()
	local frame = UIKit.panel({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(width, height), BackgroundTransparency = 0.05, Parent = self.gui })
	UIKit.padding(16).Parent = frame
	self.modal = frame
	return frame
end

function Panels:Note(title: string, body: string)
	local frame = self:_modal(420, 340)
	frame.BackgroundColor3 = Color3.fromRGB(232, 222, 196)
	UIKit.text({ Size = UDim2.new(1, 0, 0, 28), Font = Theme.Story, TextSize = 22, TextColor3 = Color3.fromRGB(50, 36, 28), Text = title, Parent = frame })
	UIKit.text({ Position = UDim2.fromOffset(0, 36), Size = UDim2.new(1, 0, 1, -84), Font = Theme.Story, TextSize = 17, TextColor3 = Color3.fromRGB(60, 46, 36), TextYAlignment = Enum.TextYAlignment.Top, Text = body, Parent = frame })
	UIKit.button("Close", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, 0), Parent = frame }, function()
		self:Close()
	end)
end

-- A row of number dials (the radio channel, the boathouse padlock...).
function Panels:Radio(digits: number, title: string?, subtitle: string?)
	local frame = self:_modal(math.max(380, digits * 70 + 60), 260)
	UIKit.text({ Size = UDim2.new(1, 0, 0, 26), Font = Theme.FontBold, TextSize = 20, TextXAlignment = Enum.TextXAlignment.Center, Text = title or "📻 Emergency radio", Parent = frame })
	UIKit.text({ Position = UDim2.fromOffset(0, 28), Size = UDim2.new(1, 0, 0, 20), TextSize = 14, TextColor3 = Theme.Muted, TextXAlignment = Enum.TextXAlignment.Center, Text = subtitle or "Set the channel from the check-in sheets", Parent = frame })

	local values = table.create(digits, 0)
	local row = UIKit.new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 60), Size = UDim2.fromOffset(digits * 70, 120), BackgroundTransparency = 1, Parent = frame }, { UIKit.list(Enum.FillDirection.Horizontal, 10) })
	for i = 1, digits do
		local column = UIKit.new("Frame", { Size = UDim2.fromOffset(60, 120), BackgroundTransparency = 1, LayoutOrder = i, Parent = row })
		local display = UIKit.text({ Position = UDim2.fromOffset(0, 40), Size = UDim2.fromOffset(60, 40), Font = Theme.FontBold, TextSize = 34, TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = Color3.fromRGB(150, 255, 170), Text = "0", Parent = column })
		local function change(delta)
			values[i] = (values[i] + delta) % 10
			display.Text = tostring(values[i])
		end
		UIKit.button("▲", { Size = UDim2.fromOffset(60, 36), Parent = column }, function()
			change(1)
		end)
		UIKit.button("▼", { Position = UDim2.fromOffset(0, 84), Size = UDim2.fromOffset(60, 36), Parent = column }, function()
			change(-1)
		end)
	end

	UIKit.button(if title and string.find(title, "padlock") then "Unlock" else "Transmit", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0), BackgroundColor3 = Color3.fromRGB(60, 110, 70) }, function()
		local parts = {}
		for _, value in values do
			table.insert(parts, tostring(value))
		end
		Net.Event("SubmitRadioCode"):FireServer(table.concat(parts))
	end).Parent = frame
	UIKit.button("Close", { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, 0, 1, 0) }, function()
		self:Close()
	end).Parent = frame
end

function Panels:Downed(info)
	if self.downed then
		self.downed:Destroy()
		self.downed = nil
	end
	if not info.downed then
		return
	end
	local frame = UIKit.panel({ AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.18, 0), Size = UDim2.fromOffset(380, 150), BackgroundColor3 = Color3.fromRGB(40, 12, 14), Parent = self.gui })
	UIKit.padding(12).Parent = frame
	self.downed = frame
	UIKit.text({ Size = UDim2.new(1, 0, 0, 28), Font = Theme.Story, TextSize = 22, TextXAlignment = Enum.TextXAlignment.Center, Text = "You were caught!", Parent = frame })
	local countdown = UIKit.text({ Position = UDim2.fromOffset(0, 32), Size = UDim2.new(1, 0, 0, 20), TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = Theme.Muted, Parent = frame })

	local secondWind = Monetization.Products.SecondWind
	if not info.secondWindUsed then
		if info.secondWinds > 0 then
			UIKit.button("Use Second Wind (" .. info.secondWinds .. ")", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, 0), Size = UDim2.fromOffset(240, 38), Parent = frame }, function()
				Net.Event("UseTool"):FireServer("SecondWind")
			end)
		elseif secondWind.id ~= 0 then
			UIKit.button("Second Wind", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, 0), Size = UDim2.fromOffset(240, 38), Parent = frame }, function()
				MarketplaceService:PromptProductPurchase(Players.LocalPlayer, secondWind.id)
			end)
		end
	end

	task.spawn(function()
		local remaining = info.bleedOut
		while frame.Parent and remaining > 0 do
			countdown.Text = string.format("A friend can help you up · waking at the checkpoint in %ds", remaining)
			task.wait(1)
			remaining -= 1
		end
	end)
end

function Panels:Results(result)
	local frame = self:_modal(420, 320)
	UIKit.text({ Size = UDim2.new(1, 0, 0, 34), Font = Theme.Story, TextSize = 28, TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = Theme.Accent, Text = string.format("Chapter %d complete", result.chapter or 1), Parent = frame })
	local minutes = math.floor(result.seconds / 60)
	local lines = {
		string.format("Time: %d:%02d", minutes, result.seconds % 60),
		string.format("+%d Embers", result.embers),
		string.format("+%d XP", result.xp),
	}
	if result.flawless then
		table.insert(lines, "Never caught! Bonus XP")
	end
	if result.firstClear then
		table.insert(lines, "First escape bonus!")
	end
	UIKit.text({ Position = UDim2.fromOffset(0, 44), Size = UDim2.new(1, 0, 0, 150), TextSize = 18, TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Top, Text = table.concat(lines, "\n"), Parent = frame })
	UIKit.text({ Position = UDim2.fromOffset(0, 200), Size = UDim2.new(1, 0, 0, 40), TextSize = 14, TextColor3 = Theme.Muted, TextXAlignment = Enum.TextXAlignment.Center, Text = if (result.chapter or 1) < #Chapters then string.format("Chapter %d is unlocked. Pick it in the lobby.", (result.chapter or 1) + 1) else "More chapters are coming. The forest isn't finished with you.", Parent = frame })
	if result.canReturn then
		UIKit.button("Back to camp", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, 0), Size = UDim2.fromOffset(180, 38), Parent = frame }, function()
			Net.Event("ReturnToLobby"):FireServer()
		end)
	else
		UIKit.text({ AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, 20), TextSize = 14, TextXAlignment = Enum.TextXAlignment.Center, Text = "The next trip leaves in " .. result.nextIn .. "s", Parent = frame })
	end
end

function Panels:Lobby()
	local frame = UIKit.panel({ Name = "Play", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -24), Size = UDim2.fromOffset(440, 170), Parent = self.gui })
	UIKit.padding(12).Parent = frame
	local title = UIKit.text({ Position = UDim2.fromOffset(40, 0), Size = UDim2.new(1, -80, 0, 26), Font = Theme.Story, TextSize = 22, TextXAlignment = Enum.TextXAlignment.Center, Parent = frame })
	local blurb = UIKit.text({ Position = UDim2.fromOffset(40, 28), Size = UDim2.new(1, -80, 0, 36), TextSize = 14, TextWrapped = true, TextColor3 = Theme.Muted, TextXAlignment = Enum.TextXAlignment.Center, Parent = frame })
	local status = UIKit.text({ Position = UDim2.fromOffset(0, 68), Size = UDim2.new(1, 0, 0, 20), TextSize = 14, TextColor3 = Theme.Muted, TextXAlignment = Enum.TextXAlignment.Center, Text = "Up to 6 players", Parent = frame })

	local selected = 1
	local queued: number? = nil
	local lastQueue = nil
	local autoPicked = false
	local button

	local function chapter()
		return Chapters[selected]
	end
	local function unlocked(): boolean
		return ChapterUnlock.isUnlocked(self.controllers.DataController.Profile, chapter())
	end
	local function refresh()
		local current = chapter()
		local open = unlocked()
		title.Text = string.format("%sChapter %d: %s", if open then "" else "🔒 ", current.id, current.name)
		blurb.Text = if open then current.blurb else string.format("Escape Chapter %d to unlock.", current.requires)
		if queued == current.id then
			button.Text = "LEAVE"
		elseif queued then
			button.Text = "SWITCH"
		else
			button.Text = if open then "PLAY" else "LOCKED"
		end
		button.AutoButtonColor = open
		button.BackgroundColor3 = if open then Color3.fromRGB(120, 80, 40) else Color3.fromRGB(70, 70, 76)
		local info = lastQueue and lastQueue.queues and lastQueue.queues[current.id]
		if info and #info.names > 0 then
			status.Text = string.format("%d/%d boarding · leaving in %ds", #info.names, lastQueue.max, info.countdown or 0)
		else
			status.Text = "Up to " .. (if lastQueue then lastQueue.max else 6) .. " players"
		end
	end

	button = UIKit.button("PLAY", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, 0), Size = UDim2.fromOffset(200, 42), BackgroundColor3 = Color3.fromRGB(120, 80, 40), TextSize = 20, Parent = frame }, function()
		if queued == chapter().id then
			Net.Event("LeaveQueue"):FireServer()
		elseif unlocked() then
			Net.Event("JoinQueue"):FireServer(chapter().id)
		end
	end)
	local function step(delta: number)
		selected = (selected - 1 + delta) % #Chapters + 1
		refresh()
	end
	if #Chapters > 1 then
		UIKit.button("◀", { Position = UDim2.fromOffset(0, 8), Size = UDim2.fromOffset(36, 48), Parent = frame }, function()
			step(-1)
		end)
		UIKit.button("▶", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 8), Size = UDim2.fromOffset(36, 48), Parent = frame }, function()
			step(1)
		end)
	end

	Net.Event("QueueUpdated").OnClientEvent:Connect(function(queue)
		lastQueue = queue
		queued = if queue.inQueue then queue.chapter else nil
		refresh()
	end)
	self.controllers.DataController:Observe(function(profile)
		-- Open on the newest chapter this player can play.
		if not autoPicked and not queued then
			autoPicked = true
			for index, entry in Chapters do
				if ChapterUnlock.isUnlocked(profile, entry) then
					selected = index
				end
			end
		end
		refresh()
	end)
	refresh()
end

return Panels
