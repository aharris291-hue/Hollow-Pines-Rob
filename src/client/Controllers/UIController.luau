-- Builds the ScreenGui and routes server messages to the HUD, menus and panels.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared.Util.Net)

local UI = script.Parent.Parent:WaitForChild("UI")
local Hud = require(UI.Hud)
local Menus = require(UI.Menus)
local Panels = require(UI.Panels)

local UIController = {}

local controllers

function UIController:Init(registry)
	controllers = registry
end

function UIController:Caption(text: string, kind: string?)
	if self.hud then
		self.hud:Caption(text, kind)
	end
end

function UIController:Start()
	local gui = Instance.new("ScreenGui")
	gui.Name = "HollowPinesUI"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	local scale = Instance.new("UIScale")
	scale.Parent = gui
	self.gui = gui

	pcall(StarterGui.SetCoreGuiEnabled, StarterGui, Enum.CoreGuiType.Health, false)

	self.hud = Hud.new(gui, controllers)
	self.menus = Menus.new(gui, controllers)
	self.panels = Panels.new(gui, controllers)

	controllers.DataController:Observe(function(profile)
		scale.Scale = profile.Settings.TextScale
	end)

	Net.Event("ObjectiveUpdated").OnClientEvent:Connect(function(text, marker)
		self.hud:SetObjective(text, marker)
	end)
	Net.Event("Caption").OnClientEvent:Connect(function(text, kind)
		self.hud:Caption(text, kind)
	end)
	Net.Event("Toast").OnClientEvent:Connect(function(text, kind)
		self.hud:Toast(text, kind)
	end)
	Net.Event("OpenPanel").OnClientEvent:Connect(function(name, data)
		if name == "Note" then
			self.panels:Note(data.title, data.body)
		elseif name == "Radio" then
			self.panels:Radio(data.digits)
		elseif name == "Close" then
			self.panels:Close()
		end
	end)
	Net.Event("DownedState").OnClientEvent:Connect(function(info)
		self.panels:Downed(info)
	end)
	Net.Event("ChapterResult").OnClientEvent:Connect(function(result)
		self.panels:Results(result)
	end)

	if ReplicatedStorage:GetAttribute("PlaceRole") == "Lobby" then
		self.panels:Lobby()
	end
end

return UIController
