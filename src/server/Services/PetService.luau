-- Cosmetic pets that float beside their owner. Purely visual.

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Items = require(Shared.Config.Items)

local PetService = {}

local services
local pets: { [Player]: BasePart } = {}

local function buildPet(def): BasePart
	local body = Instance.new("Part")
	body.Name = "Pet_" .. def.id
	body.Shape = Enum.PartType.Ball
	body.Size = Vector3.one * def.size
	body.Color = def.color
	body.Material = if def.glow > 0 then Enum.Material.Neon else Enum.Material.SmoothPlastic
	body.Transparency = if def.id == "GhostPup" then 0.45 else 0
	body.CanCollide = false
	body.CanQuery = false
	body.CanTouch = false
	body.Massless = true
	body.CastShadow = false

	if def.size >= 1 then
		-- Two little eyes so it reads as a creature rather than an orb.
		for _, side in { -1, 1 } do
			local eye = Instance.new("Part")
			eye.Name = "Eye"
			eye.Shape = Enum.PartType.Ball
			eye.Size = Vector3.one * def.size * 0.18
			eye.Color = Color3.new(0.05, 0.05, 0.05)
			eye.CanCollide = false
			eye.CanQuery = false
			eye.CanTouch = false
			eye.Massless = true
			eye.CFrame = body.CFrame * CFrame.new(side * def.size * 0.2, def.size * 0.12, -def.size * 0.42)
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = body
			weld.Part1 = eye
			weld.Parent = eye
			eye.Parent = body
		end
	end

	if def.glow > 0 then
		local light = Instance.new("PointLight")
		light.Color = def.color
		light.Range = def.glow
		light.Brightness = 1
		light.Parent = body
	end
	return body
end

local function removePet(player: Player)
	if pets[player] then
		pets[player]:Destroy()
		pets[player] = nil
	end
end

local function spawnPet(player: Player)
	removePet(player)
	local data = services.DataService:Get(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not data or not root or data.EquippedPet == "" then
		return
	end
	local def = Items.Pets[data.EquippedPet]
	if not def or not data.Owned[def.id] then
		return
	end

	local pet = buildPet(def)
	pet.CFrame = root.CFrame * CFrame.new(2.5, 2, 2)

	local petAttachment = Instance.new("Attachment")
	petAttachment.Parent = pet
	local anchor = Instance.new("Attachment")
	anchor.Name = "PetAnchor"
	anchor.Position = Vector3.new(2.5, 1.5, 2)
	anchor.Parent = root

	local align = Instance.new("AlignPosition")
	align.Attachment0 = petAttachment
	align.Attachment1 = anchor
	align.Responsiveness = 12
	align.MaxForce = 5000
	align.Parent = pet

	local orient = Instance.new("AlignOrientation")
	orient.Attachment0 = petAttachment
	orient.Attachment1 = anchor
	orient.Responsiveness = 10
	orient.Parent = pet

	pet.Parent = character
	pets[player] = pet
	pet.AncestryChanged:Connect(function()
		if not pet:IsDescendantOf(workspace) and pets[player] == pet then
			pets[player] = nil
			anchor:Destroy()
		end
	end)
end

function PetService:Init(registry)
	services = registry
end

function PetService:Start()
	local function hook(player: Player)
		player.CharacterAdded:Connect(function(character)
			character:WaitForChild("HumanoidRootPart", 10)
			services.DataService:WaitFor(player)
			spawnPet(player)
		end)
		if player.Character then
			task.spawn(spawnPet, player)
		end
	end
	Players.PlayerAdded:Connect(hook)
	for _, player in Players:GetPlayers() do
		hook(player)
	end
	Players.PlayerRemoving:Connect(removePet)
end

function PetService:Refresh(player: Player)
	spawnPet(player)
end

return PetService
