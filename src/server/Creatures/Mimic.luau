-- The Mimic (Chapter 1 teaser): it borrows voices and faces. In Chapter 1 it only
-- calls players by name from the trees and once shows itself as a "teammate"
-- standing too still at the tree line. It never chases or catches anyone yet.

local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Creatures = require(Shared.Config.Creatures)
local Assets = require(Shared.Config.Assets)
local Net = require(Shared.Util.Net)

local Mimic = {}
Mimic.__index = Mimic

local CONFIG = Creatures.Mimic

-- context = { getTargets: () -> { Player }, onFearSpike: (Player, number) -> () }
function Mimic.new(context)
	local self = setmetatable({}, Mimic)
	self.context = context
	self.active = false
	self.timer = 0
	self.decoy = nil
	return self
end

local function rootOf(player: Player): BasePart?
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function playAt(position: Vector3, soundId: number)
	if soundId == 0 then
		return
	end
	local emitter = Instance.new("Part")
	emitter.Anchored = true
	emitter.CanCollide = false
	emitter.CanQuery = false
	emitter.Transparency = 1
	emitter.Size = Vector3.one
	emitter.Position = position
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://" .. soundId
	sound.RollOffMaxDistance = 120
	sound.SoundGroup = SoundService:FindFirstChild("Effects")
	sound.Parent = emitter
	emitter.Parent = workspace
	sound:Play()
	task.delay(8, function()
		emitter:Destroy()
	end)
end

-- Calls one player by name from somewhere they can't see.
function Mimic:Whisper(target: Player)
	local root = rootOf(target)
	if not root then
		return
	end
	local line = CONFIG.voiceLines[math.random(#CONFIG.voiceLines)]
	line = string.gsub(line, "{name}", target.DisplayName)

	local behind = -root.CFrame.LookVector
	local position = root.Position + behind * 40 + Vector3.new(math.random(-15, 15), 2, math.random(-15, 15))
	playAt(position, Assets.Sounds.MimicWhisper)

	-- Captions say where it came from, so deaf and hard-of-hearing players get the same scare.
	local side = (position - root.Position).Unit:Dot(root.CFrame.RightVector)
	local direction = if math.abs(side) < 0.3 then "behind you" elseif side > 0 then "your right" else "your left"
	Net.Event("Caption"):FireClient(target, string.format("[A familiar voice, from %s] \"%s\"", direction, line), "Mimic")
	self.context.onFearSpike(target, CONFIG.fearSpike * 0.5)
end

local function fallbackDecoy(name: string): Model
	local model = Instance.new("Model")
	model.Name = name
	local torso = Instance.new("Part")
	torso.Name = "HumanoidRootPart"
	torso.Size = Vector3.new(2, 2, 1)
	torso.Color = Color3.fromRGB(70, 90, 140)
	torso.Anchored = true
	torso.CanCollide = false
	torso.Parent = model
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(1.2, 1.2, 1.2)
	head.Color = Color3.fromRGB(234, 184, 146)
	head.Anchored = true
	head.CanCollide = false
	head.CFrame = torso.CFrame * CFrame.new(0, 1.6, 0)
	head.Parent = model
	local legs = Instance.new("Part")
	legs.Name = "Legs"
	legs.Size = Vector3.new(2, 2, 1)
	legs.Color = Color3.fromRGB(40, 40, 50)
	legs.Anchored = true
	legs.CanCollide = false
	legs.CFrame = torso.CFrame * CFrame.new(0, -2, 0)
	legs.Parent = model
	model.PrimaryPart = torso
	local humanoid = Instance.new("Humanoid")
	humanoid.Parent = model
	return model
end

-- Shows a copy of `impersonated` standing at the tree line, watching `viewers`.
function Mimic:ShowDecoy(impersonated: Player, viewers: { Player })
	if self.decoy then
		return
	end
	local center, count = Vector3.zero, 0
	for _, player in viewers do
		local root = rootOf(player)
		if root then
			center += root.Position
			count += 1
		end
	end
	if count == 0 then
		return
	end
	center /= count

	local ok, model = pcall(Players.CreateHumanoidModelFromUserId, Players, impersonated.UserId)
	if not ok or not model then
		model = fallbackDecoy(impersonated.DisplayName)
	end
	model.Name = impersonated.DisplayName
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
		end
	end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.DisplayName = impersonated.DisplayName
		humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	end

	local angle = math.random() * math.pi * 2
	local distance = math.random(CONFIG.decoyDistance[1], CONFIG.decoyDistance[2])
	local position = center + Vector3.new(math.cos(angle), 0, math.sin(angle)) * distance
	model:PivotTo(CFrame.lookAt(Vector3.new(position.X, 3, position.Z), Vector3.new(center.X, 3, center.Z)))
	model.Parent = workspace
	self.decoy = { model = model, viewers = viewers, expires = os.clock() + 25, impersonated = impersonated }
end

function Mimic:_vanishDecoy(spooked: boolean)
	local decoy = self.decoy
	if not decoy then
		return
	end
	self.decoy = nil
	for _, part in decoy.model:GetDescendants() do
		if part:IsA("BasePart") then
			TweenService:Create(part, TweenInfo.new(0.6), { Transparency = 1 }):Play()
		elseif part:IsA("Decal") then
			part.Transparency = 1
		end
	end
	task.delay(0.7, function()
		decoy.model:Destroy()
	end)
	if spooked then
		for _, player in decoy.viewers do
			if player.Parent then
				local where = if decoy.impersonated == player then "It looked exactly like you." else "That wasn't " .. decoy.impersonated.DisplayName .. "."
				Net.Event("Caption"):FireClient(player, "[The figure is gone] " .. where, "Mimic")
				self.context.onFearSpike(player, CONFIG.fearSpike)
			end
		end
	end
end

-- A walkie ping "from" a teammate, at a place that teammate has never been.
function Mimic:FakePing(viewers: { Player }, from: Player, position: Vector3)
	for _, player in viewers do
		if player ~= from then
			Net.Event("WalkiePing"):FireClient(player, from, position)
		end
	end
end

function Mimic:SetActive(active: boolean)
	self.active = active
	self.timer = math.random(CONFIG.voiceInterval[1], CONFIG.voiceInterval[2]) * 0.5
	if not active then
		self:_vanishDecoy(false)
	end
end

function Mimic:Update(dt: number)
	if self.decoy then
		local position = self.decoy.model:GetPivot().Position
		local someoneClose = false
		for _, player in self.context.getTargets() do
			local root = rootOf(player)
			if root and (root.Position - position).Magnitude < CONFIG.decoyVanishDistance then
				someoneClose = true
			end
		end
		if someoneClose or os.clock() > self.decoy.expires then
			self:_vanishDecoy(someoneClose)
		end
	end

	if not self.active then
		return
	end
	self.timer -= dt
	if self.timer <= 0 then
		self.timer = math.random(CONFIG.voiceInterval[1], CONFIG.voiceInterval[2])
		local targets = self.context.getTargets()
		if #targets > 0 then
			self:Whisper(targets[math.random(#targets)])
		end
	end
end

function Mimic:Destroy()
	self.active = false
	self:_vanishDecoy(false)
end

return Mimic
