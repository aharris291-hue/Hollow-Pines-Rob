-- Chapter intros (the bus crash, the rescue truck) and the photograph endings.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Net = require(Shared.Util.Net)
local UI = script.Parent.Parent:WaitForChild("UI")
local UIKit = require(UI.UIKit)

local CutsceneController = {}

local player = Players.LocalPlayer
local controllers
local gui: ScreenGui

local function overlay(): (Frame, TextLabel)
	local frame = UIKit.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, ZIndex = 20, Parent = gui })
	local label = UIKit.text({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(0.8, 0, 0, 120), TextXAlignment = Enum.TextXAlignment.Center, Font = UIKit.Theme.Story, TextSize = 34, ZIndex = 21, Text = "", Parent = frame })
	return frame, label
end

local function fade(frame: Frame, label: TextLabel?, to: number, seconds: number)
	TweenService:Create(frame, TweenInfo.new(seconds), { BackgroundTransparency = to }):Play()
	if label then
		TweenService:Create(label, TweenInfo.new(seconds), { TextTransparency = to }):Play()
	end
	task.wait(seconds)
end

local function playRangerIntro(data, frame: Frame, label: TextLabel)
	local someone = if data.names and #data.names > 0 then data.names[math.random(#data.names)] else player.DisplayName
	controllers.UIController:Caption("[An engine idles. Rain ticks on the roof of the rescue truck]", "Sound")
	task.wait(1.5)
	controllers.UIController:Caption(string.format("%s: \"Why did we stop? Where did the driver go?\"", someone), "Story")
	task.wait(2.2)
	controllers.UIController:Caption("[Walkie, crackling] \"...truck seven, report... truck seven...\"", "Radio")
	task.wait(math.max(0.5, data.length - 10))
	label.Text = ""
	fade(frame, label, 1, 1.5)
	frame:Destroy()
	controllers.UIController:Caption("The rescue truck stopped at the gate of an old campground. The driver is gone.", "Story")
end

local function playIntro(data)
	local frame, label = overlay()
	label.Text = "THE HOLLOW PINES"
	task.wait(2)
	label.Text = string.format("Chapter %d\n%s", data.chapter or 1, data.title or "The Storm")
	task.wait(2)
	label.Text = ""
	fade(frame, nil, 0.25, 0.8)
	if (data.chapter or 1) ~= 1 then
		playRangerIntro(data, frame, label)
		return
	end

	local someone = if data.names and #data.names > 0 then data.names[math.random(#data.names)] else player.DisplayName
	controllers.UIController:Caption("[Rain hammers the bus windows]", "Sound")
	controllers.FearController:Shake(0.05, 3)
	task.wait(1.5)
	controllers.UIController:Caption(string.format("%s: \"Mr. Dorsey, why are we going this way?\"", someone), "Story")
	task.wait(2)
	controllers.UIController:Caption("Mr. Dorsey: \"Shortcut. Everyone sit down and hold on.\"", "Story")
	task.wait(1.8)

	-- The crash.
	controllers.AudioController:Play(data.crashSound, 1)
	controllers.FearController:Shake(0.8, 1.2)
	if not controllers.DataController:Setting("ReducedFlashing") then
		frame.BackgroundColor3 = Color3.new(1, 1, 1)
		frame.BackgroundTransparency = 0
		task.wait(0.08)
	end
	frame.BackgroundColor3 = Color3.new(0, 0, 0)
	frame.BackgroundTransparency = 0
	label.TextTransparency = 0
	label.Text = "..."
	task.wait(math.max(0.5, data.length - 9.5))
	label.Text = ""
	fade(frame, label, 1, 1.5)
	frame:Destroy()
	controllers.UIController:Caption("You wake up. The bus has crashed nose-first into a tree. The driver's seat is empty.", "Story")
end

local function stageCharacter(model: Model, cframe: CFrame)
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
		elseif descendant:IsA("Script") or descendant:IsA("LocalScript") or descendant:IsA("Sound") then
			descendant:Destroy()
		end
	end
	model:PivotTo(cframe)
end

local function buildPhoto(parent: Frame, userIds: { number }, scene: string?)
	local viewport = UIKit.new("ViewportFrame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.fromRGB(30, 28, 34),
		Ambient = Color3.fromRGB(150, 130, 110),
		LightColor = Color3.fromRGB(255, 225, 190),
		LightDirection = Vector3.new(-0.3, -1, -0.6),
		ImageColor3 = Color3.fromRGB(235, 215, 190), -- old-photo warmth
		Parent = parent,
	})
	local world = Instance.new("WorldModel")
	world.Parent = viewport

	local function block(size, cframe, color, material)
		UIKit.new("Part", { Anchored = true, Size = size, CFrame = cframe, Color = color, Material = material or Enum.Material.SmoothPlastic, Parent = world })
	end
	local tower = scene == "Tower"
	-- Where the group stands: beside the bus, or up on the lookout platform.
	local standY = if tower then 30 else 3
	block(Vector3.new(200, 1, 200), CFrame.new(0, -0.5, 0), Color3.fromRGB(40, 50, 36), Enum.Material.Grass)
	if tower then
		local wood = Color3.fromRGB(96, 70, 48)
		for _, x in { -9, 9 } do
			for _, z in { -3, 9 } do
				block(Vector3.new(1, 27, 1), CFrame.new(x, 13.5, z), wood, Enum.Material.Wood)
			end
		end
		block(Vector3.new(22, 1, 16), CFrame.new(0, 27.5, 3), Color3.fromRGB(82, 62, 46), Enum.Material.WoodPlanks)
		block(Vector3.new(22, 1, 16), CFrame.new(0, 37, 3), Color3.fromRGB(56, 44, 40), Enum.Material.Slate)
		-- Ranger Hale at the foot of the ladder, lantern raised.
		local coat = Color3.fromRGB(70, 60, 40)
		block(Vector3.new(2.2, 5, 1.2), CFrame.new(12, 4.5, 8), coat)
		block(Vector3.new(3, 0.4, 3), CFrame.new(12, 8, 8), Color3.fromRGB(90, 70, 40))
		block(Vector3.new(0.8, 1, 0.8), CFrame.new(13.6, 7.5, 8.6), Color3.fromRGB(255, 200, 110), Enum.Material.Neon)
	else
		block(Vector3.new(10, 9, 30), CFrame.new(-6, 4.5, -10) * CFrame.Angles(0, math.rad(70), math.rad(4)), Color3.fromRGB(225, 170, 40), Enum.Material.Metal)
	end
	for i = 1, 14 do
		local x = -40 + i * 6 + math.random(-2, 2)
		local z = -30 - math.random(0, 18)
		block(Vector3.new(2, 30, 2), CFrame.new(x, 15, z), Color3.fromRGB(30, 24, 20), Enum.Material.Wood)
	end

	-- The group, lined up as if posing for the picture.
	local count = 0
	for _, userId in userIds do
		local other = Players:GetPlayerByUserId(userId)
		local character = other and other.Character
		if character then
			local previous = character.Archivable
			character.Archivable = true
			local copy = character:Clone()
			character.Archivable = previous
			if copy then
				count += 1
				local x = (count - 1) * 3.4 - (#userIds - 1) * 1.7
				stageCharacter(copy, CFrame.new(x, standY, 4))
				copy.Parent = world
			end
		end
	end

	-- And somewhere it shouldn't be, something tall: between the trees behind
	-- the bus, or standing on the tower roof above everyone.
	local watcher = Color3.fromRGB(8, 8, 10)
	local w = if tower then Vector3.new(4, 37.5, 2) else Vector3.new(5, 0, -22)
	block(Vector3.new(1.8, 6, 1), CFrame.new(w + Vector3.new(0, 8.5, 0)), watcher)
	UIKit.new("Part", { Anchored = true, Shape = Enum.PartType.Ball, Size = Vector3.new(1.6, 1.6, 1.6), CFrame = CFrame.new(w + Vector3.new(0, 12.3, 0)), Color = watcher, Parent = world })
	block(Vector3.new(0.5, 7, 0.5), CFrame.new(w + Vector3.new(-1.2, 7, 0)), watcher)
	block(Vector3.new(0.5, 7, 0.5), CFrame.new(w + Vector3.new(1.2, 7, 0)), watcher)
	block(Vector3.new(0.6, 5.5, 0.6), CFrame.new(w + Vector3.new(-0.5, 2.75, 0)), watcher)
	block(Vector3.new(0.6, 5.5, 0.6), CFrame.new(w + Vector3.new(0.5, 2.75, 0)), watcher)

	local camera = Instance.new("Camera")
	camera.FieldOfView = if tower then 60 else 50
	camera.CFrame = if tower
		then CFrame.lookAt(Vector3.new(-6, 44, 40), Vector3.new(2, 26, 2))
		else CFrame.lookAt(Vector3.new(0, 5.5, 26), Vector3.new(0, 5, -6))
	camera.Parent = viewport
	viewport.CurrentCamera = camera
end

local function playEnding(data)
	local frame, _ = overlay()
	frame.BackgroundTransparency = 1
	fade(frame, nil, 0, 1.5)

	local polaroid = UIKit.new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.42), Size = UDim2.fromOffset(420, 470), BackgroundColor3 = Color3.fromRGB(240, 236, 226), BorderSizePixel = 0, Rotation = -3, ZIndex = 22, Parent = frame }, { UIKit.corner(4) })
	local photoArea = UIKit.new("Frame", { Position = UDim2.fromOffset(20, 20), Size = UDim2.new(1, -40, 0, 360), BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = 23, Parent = polaroid })
	buildPhoto(photoArea, data.userIds, data.scene)
	UIKit.text({ Position = UDim2.new(0, 20, 1, -76), Size = UDim2.new(1, -40, 0, 50), Font = Enum.Font.IndieFlower, TextSize = 28, TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = Color3.fromRGB(40, 40, 60), Text = "say cheese :)", ZIndex = 23, Parent = polaroid })

	local story = UIKit.text({ AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.42, 250), Size = UDim2.new(0.8, 0, 0, 110), Font = UIKit.Theme.Story, TextSize = 19, TextXAlignment = Enum.TextXAlignment.Center, TextTransparency = 1, ZIndex = 22, Text = data.text, Parent = frame })
	TweenService:Create(story, TweenInfo.new(2), { TextTransparency = 0 }):Play()
	task.wait(data.hold)
	fade(frame, nil, 1, 1.5)
	frame:Destroy()
end

function CutsceneController:Init(registry)
	controllers = registry
end

function CutsceneController:Start()
	gui = Instance.new("ScreenGui")
	gui.Name = "Cutscenes"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 40
	gui.Parent = player:WaitForChild("PlayerGui")

	Net.Event("Cutscene").OnClientEvent:Connect(function(name, data)
		if name == "Intro" then
			playIntro(data)
		end
	end)
	Net.Event("PhotoEnding").OnClientEvent:Connect(playEnding)
end

return CutsceneController
