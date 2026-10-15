-- Turns the server's fear value into what the player feels: a darkening
-- vignette, draining colour, a heartbeat, and (unless turned off) camera shake.

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Assets = require(Shared.Config.Assets)
local GameConfig = require(Shared.Config.GameConfig)

local FearController = {}

local player = Players.LocalPlayer
local controllers
local grade: ColorCorrectionEffect
local blur: BlurEffect
local vignette: { Frame } = {}
local shakeUntil, shakeStrength = 0, 0
local displayed = 0

local function buildVignette()
	local gui = Instance.new("ScreenGui")
	gui.Name = "FearVignette"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = -1
	gui.Parent = player:WaitForChild("PlayerGui")
	-- Four edge gradients make a vignette without needing an image asset.
	local edges = {
		{ UDim2.new(1, 0, 0.35, 0), UDim2.new(0, 0, 0, 0), 90 },
		{ UDim2.new(1, 0, 0.35, 0), UDim2.new(0, 0, 0.65, 0), -90 },
		{ UDim2.new(0.3, 0, 1, 0), UDim2.new(0, 0, 0, 0), 0 },
		{ UDim2.new(0.3, 0, 1, 0), UDim2.new(0.7, 0, 0, 0), 180 },
	}
	for _, edge in edges do
		local frame = Instance.new("Frame")
		frame.Size = edge[1]
		frame.Position = edge[2]
		frame.BorderSizePixel = 0
		frame.BackgroundColor3 = Color3.new(0, 0, 0)
		frame.BackgroundTransparency = 1
		local gradient = Instance.new("UIGradient")
		gradient.Rotation = edge[3]
		gradient.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 1),
		})
		gradient.Parent = frame
		frame.Parent = gui
		table.insert(vignette, frame)
	end
end

function FearController:Init(registry)
	controllers = registry
end

-- Shared camera shake used by fear, thunder and stings. Respects ReducedShake.
function FearController:Shake(strength: number, seconds: number)
	if controllers.DataController:Setting("ReducedShake") then
		return
	end
	shakeStrength = math.max(shakeStrength, strength)
	shakeUntil = math.max(shakeUntil, os.clock() + seconds)
end

function FearController:Start()
	if game:GetService("ReplicatedStorage"):GetAttribute("PlaceRole") == "Lobby" then
		return
	end
	grade = Instance.new("ColorCorrectionEffect")
	grade.Name = "FearGrade"
	grade.Parent = Lighting
	blur = Instance.new("BlurEffect")
	blur.Name = "FearBlur"
	blur.Size = 0
	blur.Parent = Lighting
	buildVignette()

	RunService.RenderStepped:Connect(function(dt)
		local target = player:GetAttribute("Fear") or 0
		displayed += (target - displayed) * math.min(1, dt * 3)
		local calmer = controllers.DataController:Setting("CalmerScares")
		local intensity = (displayed / GameConfig.Fear.Max) * (if calmer then 0.6 else 1)

		grade.Saturation = -0.6 * intensity
		grade.Contrast = 0.15 * intensity
		blur.Size = if intensity > 0.85 then (intensity - 0.85) * 40 else 0
		for _, frame in vignette do
			frame.BackgroundTransparency = 1 - math.clamp(intensity * 1.1, 0, 0.92)
		end

		local heartbeat = controllers.AudioController:GetLoop("Heartbeat")
		if intensity > 0.35 then
			if not heartbeat then
				controllers.AudioController:Loop("Heartbeat", Assets.Sounds.Heartbeat, 0, "Effects")
				heartbeat = controllers.AudioController:GetLoop("Heartbeat")
			end
			if heartbeat then
				heartbeat.Volume = (intensity - 0.35) * 1.4
				heartbeat.PlaybackSpeed = 0.9 + intensity * 0.5
			end
		elseif heartbeat then
			controllers.AudioController:StopLoop("Heartbeat")
		end

		if intensity > 0.9 then
			FearController:Shake(0.08, 0.1)
		end

		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			if os.clock() < shakeUntil then
				humanoid.CameraOffset = Vector3.new(
					(math.random() - 0.5) * shakeStrength,
					(math.random() - 0.5) * shakeStrength,
					0
				)
			else
				shakeStrength = 0
				humanoid.CameraOffset = Vector3.zero
			end
		end
	end)
end

return FearController
