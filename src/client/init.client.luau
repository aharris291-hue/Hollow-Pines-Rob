-- Client entry point: Init every controller, then Start them.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

ReplicatedStorage:WaitForChild("Shared")
ReplicatedStorage:WaitForChild("Remotes")

local ORDER = {
	"DataController",
	"AudioController",
	"InputController",
	"AtmosphereController",
	"FearController",
	"UIController",
	"CutsceneController",
}

local folder = script:WaitForChild("Controllers")
local controllers = {}
for _, name in ORDER do
	controllers[name] = require(folder:WaitForChild(name))
end
for _, name in ORDER do
	if controllers[name].Init then
		controllers[name]:Init(controllers)
	end
end
for _, name in ORDER do
	if controllers[name].Start then
		task.spawn(controllers[name].Start, controllers[name])
	end
end

Players.LocalPlayer:SetAttribute("ClientReady", true)
