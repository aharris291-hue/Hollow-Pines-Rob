-- The secret handshake (Chapter 3). Press H (or tap Shake) next to someone:
-- a real teammate can shake back within a few seconds, and both are trusted
-- and calmer. The Mimic's copy can't shake back: offering it a handshake
-- exposes it.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)
local Net = require(Shared.Util.Net)
local RateLimit = require(Shared.Util.RateLimit)
local Trust = require(Shared.Util.Trust)
local EventBus = require(script.Parent.Parent.EventBus)

local TrustService = {}

local CONFIG = GameConfig.Trust

local services
local offers: { [Player]: { target: any, at: number } } = {}
local limiter = RateLimit.new(CONFIG.Cooldown)

local function rootOf(player: Player): BasePart?
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function showHand(player: Player)
	local head = player.Character and player.Character:FindFirstChild("Head")
	if not head then
		return
	end
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Handshake"
	billboard.Size = UDim2.fromOffset(60, 60)
	billboard.StudsOffset = Vector3.new(0, 2.6, 0)
	billboard.AlwaysOnTop = true
	billboard.LightInfluence = 0
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Text = "🤝"
	label.Parent = billboard
	billboard.Parent = head
	task.delay(CONFIG.Window, function()
		billboard:Destroy()
	end)
end

-- Is anyone else (still in the game, not caught) close to this player?
function TrustService:IsAlone(player: Player): boolean
	local root = rootOf(player)
	if not root then
		return false
	end
	local others = {}
	for _, other in Players:GetPlayers() do
		local otherRoot = other ~= player and not other:GetAttribute("Downed") and not other:GetAttribute("Escaped") and rootOf(other)
		if otherRoot then
			table.insert(others, otherRoot.Position)
		end
	end
	return Trust.isAlone(root.Position, others, CONFIG.AloneRadius)
end

function TrustService:_offer(player: Player)
	local root = rootOf(player)
	if not root or player:GetAttribute("Downed") then
		return
	end
	showHand(player)

	-- Whoever is closest gets the offer: a teammate, or the copy.
	local best, bestDistance = nil, CONFIG.Range
	for _, other in Players:GetPlayers() do
		local otherRoot = other ~= player and rootOf(other)
		if otherRoot then
			local distance = (otherRoot.Position - root.Position).Magnitude
			if distance < bestDistance then
				best, bestDistance = other, distance
			end
		end
	end
	local copy = services.CreatureService.copy
	local copyPosition = copy and copy:Position()
	if copyPosition and (copyPosition - root.Position).Magnitude < bestDistance then
		EventBus.Fire("MimicRevealed", player)
		copy:Reveal(player)
		return
	end
	if not best then
		Net.Event("Toast"):FireClient(player, "Nobody close enough to shake hands with.", "Info")
		return
	end

	local now = os.clock()
	offers[player] = { target = best, at = now }
	if Trust.handshake(offers, player, best, now, CONFIG.Window) then
		offers[player], offers[best] = nil, nil
		for _, who in { player, best } do
			local partner = if who == player then best else player
			services.FearService:Reduce(who, CONFIG.TrustedCalm)
			EventBus.Fire("Handshake", who)
			Net.Event("ScreenEffect"):FireClient(who, "TrustConfirmed", {})
			Net.Event("Toast"):FireClient(who, partner.DisplayName .. " shook back. It's really them.", "Success")
		end
	else
		Net.Event("Caption"):FireClient(best, player.DisplayName .. " offers the secret handshake. Press H, or tap Shake, to shake back.", "Hint")
	end
end

function TrustService:Init(registry)
	services = registry
	Net.Event("Handshake").OnServerEvent:Connect(function(player)
		if (ReplicatedStorage:GetAttribute("Chapter") or 1) < 3 or not limiter:Allow(player) then
			return
		end
		if services.ChapterService:IsGameplayActive() then
			self:_offer(player)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		offers[player] = nil
	end)
end

function TrustService:ResetRun()
	table.clear(offers)
end

return TrustService
