-- Rain around the camera, lightning, one-shot screen effects from the server,
-- and walkie-talkie pings shown in the world.

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared.Util.Net)
local Assets = require(Shared.Config.Assets)

local AtmosphereController = {}

local player = Players.LocalPlayer
local controllers
local flashFrame: Frame

local function buildRain()
	local emitterPart = Instance.new("Part")
	emitterPart.Name = "RainEmitter"
	emitterPart.Anchored = true
	emitterPart.CanCollide = false
	emitterPart.CanQuery = false
	emitterPart.CanTouch = false
	emitterPart.Transparency = 1
	emitterPart.Size = Vector3.new(120, 1, 120)
	local rain = Instance.new("ParticleEmitter")
	rain.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	rain.Color = ColorSequence.new(Color3.fromRGB(170, 190, 220))
	rain.LightEmission = 0.1
	rain.LightInfluence = 1
	rain.Transparency = NumberSequence.new(0.55)
	rain.Size = NumberSequence.new(0.12)
	rain.Squash = NumberSequence.new(3.5)
	rain.Orientation = Enum.ParticleOrientation.VelocityParallel
	rain.Rate = 900
	rain.Lifetime = NumberRange.new(0.9, 1.1)
	rain.Speed = NumberRange.new(70, 80)
	rain.EmissionDirection = Enum.NormalId.Bottom
	rain.SpreadAngle = Vector2.new(4, 4)
	rain.Acceleration = Vector3.new(4, 0, 2)
	rain.Parent = emitterPart
	emitterPart.Parent = workspace.CurrentCamera

	RunService.RenderStepped:Connect(function()
		local camera = workspace.CurrentCamera
		if camera then
			emitterPart.CFrame = CFrame.new(camera.CFrame.Position + Vector3.new(0, 40, 0))
		end
	end)
end

local function flash(color: Color3, peak: number, seconds: number)
	-- Reduced flashing swaps strobes for a gentle dim pulse.
	if controllers.DataController:Setting("ReducedFlashing") then
		color = Color3.new(0, 0, 0)
		peak = math.max(peak, 0.85)
	end
	flashFrame.BackgroundColor3 = color
	flashFrame.BackgroundTransparency = peak
	TweenService:Create(flashFrame, TweenInfo.new(seconds), { BackgroundTransparency = 1 }):Play()
end

local function soundCaption(text: string)
	if controllers.DataController:Setting("Captions") ~= false then
		controllers.UIController:Caption(text, "Sound")
	end
end

local EFFECTS = {
	Thunder = function(payload)
		flash(Color3.new(1, 1, 1), 0.35, 0.6)
		local original = Lighting.Brightness
		if not controllers.DataController:Setting("ReducedFlashing") then
			Lighting.Brightness = original + 2
			task.delay(0.15, function()
				Lighting.Brightness = original
			end)
		end
		task.delay(1.2, function()
			controllers.AudioController:Play(payload.soundId, 0.9)
			controllers.FearController:Shake(0.25, 0.6)
		end)
		soundCaption("[Thunder rumbles]")
	end,
	WatcherSting = function(payload)
		controllers.AudioController:Play(payload.soundId, 1)
		controllers.FearController:Shake(0.35, 0.4)
		soundCaption("[A sharp, cold sting of sound]")
	end,
	CameraFlash = function(payload)
		flash(Color3.new(1, 1, 1), 0.1, 0.5)
		controllers.AudioController:Play(payload.soundId, 0.8)
	end,
	PowerOn = function(payload)
		controllers.AudioController:Play(payload.soundId, 0.8)
		soundCaption("[Generator hum]")
	end,
	RadioStatic = function(payload)
		controllers.AudioController:Play(payload.soundId, 0.7)
		soundCaption("[Radio static]")
	end,
	ChaseStart = function(payload)
		controllers.AudioController:Loop("Chase", payload.soundId, 0.7, "Music")
		controllers.FearController:Shake(0.3, 0.8)
		soundCaption("[Heavy footsteps crash through the trees]")
	end,
	ChaseEnd = function()
		controllers.AudioController:StopLoop("Chase")
	end,
	RangerSpotted = function(payload)
		controllers.AudioController:Play(payload.soundId, 1)
		controllers.FearController:Shake(0.3, 0.4)
		flash(Color3.fromRGB(255, 200, 120), 0.25, 0.5)
		soundCaption("[A lantern swings towards you. Heavy boots, closer.]")
	end,
	Padlock = function(payload)
		controllers.AudioController:Play(payload.soundId, 0.8)
		soundCaption("[The padlock clicks open]")
	end,
	Flare = function(payload)
		controllers.AudioController:Play(payload.soundId, 1)
		soundCaption("[A flare whooshes into the sky and bursts]")
		if controllers.DataController:Setting("ReducedFlashing") then
			return
		end
		-- The whole sky glows red while the flare burns.
		local glow = Instance.new("ColorCorrectionEffect")
		glow.Name = "FlareGlow"
		glow.TintColor = Color3.fromRGB(255, 170, 160)
		glow.Brightness = 0.08
		glow.Parent = Lighting
		TweenService:Create(glow, TweenInfo.new(14, Enum.EasingStyle.Sine), { TintColor = Color3.new(1, 1, 1), Brightness = 0 }):Play()
		task.delay(14, function()
			glow:Destroy()
		end)
	end,
	Bell = function(payload)
		controllers.AudioController:Play(payload.soundId, 1)
		soundCaption("[A bell rings out across the fog]")
	end,
	FerryHorn = function(payload)
		controllers.AudioController:Play(payload.soundId, 1)
		controllers.FearController:Shake(0.1, 1)
		soundCaption("[A deep ferry horn, far across the water]")
	end,
	MimicRevealed = function(payload)
		controllers.AudioController:Play(payload.soundId, 1)
		controllers.FearController:Shake(0.4, 0.6)
		flash(Color3.fromRGB(200, 170, 255), 0.35, 0.7)
		soundCaption("[A voice that is everyone's voice at once, then silence]")
	end,
	Wake = function(payload)
		controllers.AudioController:Play(payload.soundId, 0.9)
		soundCaption("[Wood creaks and cracks, then a deep breath]")
	end,
	Brazier = function(payload)
		controllers.AudioController:Play(payload.soundId, 0.9)
		flash(Color3.fromRGB(255, 190, 110), 0.2, 0.6)
		soundCaption("[Fire roars up in the stone bowl]")
	end,
	GazeSting = function(payload)
		controllers.AudioController:Play(payload.soundId, 1)
		controllers.FearController:Shake(0.25, 0.5)
		soundCaption("[A low groan, like a whole tree bending]")
	end,
	Remember = function()
		flash(Color3.fromRGB(255, 230, 170), 0.3, 2.5)
		controllers.FearController:Shake(0.3, 2)
		soundCaption("[The whole forest sighs]")
	end,
	TrustConfirmed = function()
		flash(Color3.fromRGB(150, 230, 160), 0.2, 0.6)
	end,
	Helicopter = function(payload)
		controllers.AudioController:Play(payload.soundId, 1)
		controllers.FearController:Shake(0.15, 2)
		soundCaption("[Helicopter rotors, getting louder]")
	end,
}

local function showPing(from: Player, position: Vector3)
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.Transparency = 1
	anchor.Size = Vector3.one
	anchor.Position = position + Vector3.new(0, 4, 0)
	local billboard = Instance.new("BillboardGui")
	billboard.AlwaysOnTop = true
	billboard.Size = UDim2.fromOffset(160, 50)
	billboard.LightInfluence = 0
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(120, 220, 255)
	label.TextStrokeTransparency = 0.4
	label.Text = "📻 " .. from.DisplayName
	label.Parent = billboard
	billboard.Parent = anchor
	anchor.Parent = workspace
	task.delay(6, function()
		anchor:Destroy()
	end)
end

function AtmosphereController:Init(registry)
	controllers = registry
end

function AtmosphereController:Start()
	local gui = Instance.new("ScreenGui")
	gui.Name = "Flash"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 50
	gui.Parent = player:WaitForChild("PlayerGui")
	flashFrame = Instance.new("Frame")
	flashFrame.Size = UDim2.fromScale(1, 1)
	flashFrame.BorderSizePixel = 0
	flashFrame.BackgroundTransparency = 1
	flashFrame.Parent = gui

	Net.Event("ScreenEffect").OnClientEvent:Connect(function(name, payload)
		local handler = EFFECTS[name]
		if handler then
			handler(payload or {})
		end
	end)
	Net.Event("WalkiePing").OnClientEvent:Connect(showPing)

	-- Chapter 4: the screen glows gold while The Hollow One's gaze is on you.
	local gazeFrame = Instance.new("Frame")
	gazeFrame.Size = UDim2.fromScale(1, 1)
	gazeFrame.BorderSizePixel = 0
	gazeFrame.BackgroundColor3 = Color3.fromRGB(255, 200, 110)
	gazeFrame.BackgroundTransparency = 1
	gazeFrame.Parent = gui
	local gazeLabel = Instance.new("TextLabel")
	gazeLabel.AnchorPoint = Vector2.new(0.5, 0)
	gazeLabel.Position = UDim2.new(0.5, 0, 0.22, 0)
	gazeLabel.Size = UDim2.fromOffset(520, 40)
	gazeLabel.BackgroundTransparency = 1
	gazeLabel.Font = Enum.Font.GothamBold
	gazeLabel.TextSize = 24
	gazeLabel.TextColor3 = Color3.fromRGB(255, 230, 170)
	gazeLabel.TextStrokeTransparency = 0.3
	gazeLabel.Text = "It sees you! Get behind a stone!"
	gazeLabel.Visible = false
	gazeLabel.Parent = gui
	player:GetAttributeChangedSignal("Gaze"):Connect(function()
		local gaze = player:GetAttribute("Gaze") or 0
		gazeFrame.BackgroundTransparency = 1 - 0.45 * math.clamp(gaze, 0, 1)
		gazeLabel.Visible = gaze > 0.15
	end)

	if ReplicatedStorage:GetAttribute("PlaceRole") ~= "Lobby" then
		buildRain()
		controllers.AudioController:Loop("Rain", Assets.Sounds.Rain, 0.4, "Effects")
	end
end

return AtmosphereController
