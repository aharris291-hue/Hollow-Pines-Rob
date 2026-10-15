-- First-time hints and the analytics funnel for Chapter 1.
--
-- Hints are shown once per account (remembered in profile.HintsSeen), at the
-- moment they matter: how to interact when the first prompt appears, how to use
-- the light when it is handed out, what fear means when it first rises.
--
-- Funnel steps go to Roblox Analytics twice: as the onboarding funnel (counted
-- once per new player, shows where first-timers drop off) and as a "Chapter1"
-- funnel per run (shows where every run drops off).

local AnalyticsService = game:GetService("AnalyticsService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Net = require(Shared.Util.Net)
local EventBus = require(script.Parent.Parent.EventBus)

local OnboardingService = {}

local HINTS = {
	Move = "Move with WASD or the thumbstick. Drag or move the mouse to look around.",
	Interact = "Walk up to a prompt and press E, or tap it, to interact.",
	Light = "Press F, or tap Light, to switch your light on. Batteries run out, so save them.",
	Fear = "Your fear rises in the dark and when you're alone. Stay near friends and keep a light on.",
	Watcher = "Don't stare at it. It only moves when nobody is looking.",
	Revive = "A friend was caught! Stand next to them and hold E to help them up.",
	Sprint = "Hold Shift, or tap Run, to sprint. Stamina refills while you walk.",
}

local services
local runId = ""

function OnboardingService:Init(registry)
	services = registry
end

function OnboardingService:Start()
	local function watchFear(player: Player)
		player:GetAttributeChangedSignal("FearTier"):Connect(function()
			local tier = player:GetAttribute("FearTier")
			if tier and tier ~= "Calm" then
				self:Hint(player, "Fear")
			end
		end)
	end
	Players.PlayerAdded:Connect(watchFear)
	for _, player in Players:GetPlayers() do
		watchFear(player)
	end

	EventBus.Event:Connect(function(name, player)
		if name == "WatcherSpotted" and player then
			self:Hint(player, "Watcher")
		end
	end)

	services.PlayerStateService.Downed:Connect(function(downed)
		for _, other in Players:GetPlayers() do
			if other ~= downed then
				self:Hint(other, "Revive")
			end
		end
	end)
end

-- Shows a hint unless this player has seen it before.
function OnboardingService:Hint(player: Player, hintId: string)
	local text = HINTS[hintId]
	local data = services.DataService:Get(player)
	if not text or not data or data.HintsSeen[hintId] then
		return
	end
	services.DataService:Update(player, function(d)
		d.HintsSeen[hintId] = true
	end)
	Net.Event("Hint"):FireClient(player, text)
end

function OnboardingService:HintAll(hintId: string)
	for _, player in Players:GetPlayers() do
		self:Hint(player, hintId)
	end
end

function OnboardingService:NewRun()
	runId = HttpService:GenerateGUID(false)
end

function OnboardingService:Step(step: number, stepName: string)
	for _, player in Players:GetPlayers() do
		local data = services.DataService:Get(player)
		if data and data.Stats.ChaptersCompleted == 0 then
			pcall(AnalyticsService.LogOnboardingFunnelStepEvent, AnalyticsService, player, step, stepName)
		end
		pcall(AnalyticsService.LogFunnelStepEvent, AnalyticsService, player, "Chapter1", runId, step, stepName)
	end
end

return OnboardingService
