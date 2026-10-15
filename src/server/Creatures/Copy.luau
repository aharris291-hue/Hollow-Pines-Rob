-- The Mimic's walking form (Chapter 3). It steps out of the fog wearing one of
-- the players: their avatar, their name. It walks a little wrong (it slides, it
-- never carries a light), and it only catches someone who is alone. Next to a
-- group it just creeps closer and waits. A secret handshake exposes it: real
-- teammates shake back, the copy can't.
--
-- Modes: Hidden (gone, waiting to reappear), Stalk, Hunt (finale: chases the
-- nearest player it can reach, alone or not).

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Creatures = require(Shared.Config.Creatures)
local Mover = require(script.Parent.Mover)

local Copy = {}
Copy.__index = Copy

local CONFIG = Creatures.Copy

local function rootOf(player: Player): BasePart?
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function stripped(model: Model)
	for _, child in model:GetDescendants() do
		if child:IsA("Tool") or child:IsA("Script") or child:IsA("LocalScript") or child:IsA("Sound") or child:IsA("ForceField") or child:IsA("Light") then
			child:Destroy()
		elseif child:IsA("BasePart") then
			child.CanTouch = false
			child.Anchored = false
		end
	end
	for _, child in model:GetChildren() do
		if child:IsA("BillboardGui") then
			child:Destroy()
		end
	end
end

-- A plain stand-in if the player's avatar can't be copied.
local function fallbackBody(name: string): Model
	local model = Instance.new("Model")
	model.Name = name
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2, 2, 1)
	root.Transparency = 1
	root.CanCollide = false
	root.Parent = model
	model.PrimaryPart = root
	for _, piece in {
		{ "Torso", Vector3.new(2, 2, 1), CFrame.new(0, 0, 0), Color3.fromRGB(70, 90, 140) },
		{ "Head", Vector3.new(1.2, 1.2, 1.2), CFrame.new(0, 1.6, 0), Color3.fromRGB(234, 184, 146) },
		{ "Legs", Vector3.new(2, 2, 1), CFrame.new(0, -2, 0), Color3.fromRGB(40, 40, 50) },
	} do
		local part = Instance.new("Part")
		part.Name = piece[1]
		part.Size = piece[2]
		part.Color = piece[4]
		part.CanCollide = false
		part.Massless = true
		part.CFrame = root.CFrame * piece[3]
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = root
		weld.Part1 = part
		weld.Parent = part
		part.Parent = model
	end
	local humanoid = Instance.new("Humanoid")
	humanoid.HipHeight = 3
	humanoid.Parent = model
	return model
end

local function buildCopyOf(player: Player): Model
	local model: Model? = nil
	local character = player.Character
	if character then
		local previous = character.Archivable
		character.Archivable = true
		local ok, clone = pcall(character.Clone, character)
		character.Archivable = previous
		if ok and clone and clone:FindFirstChildOfClass("Humanoid") and clone:FindFirstChild("HumanoidRootPart") then
			model = clone
		end
	end
	if not model then
		model = fallbackBody(player.DisplayName)
	end
	local body = model :: Model
	stripped(body)
	body.Name = "Copy_" .. player.Name
	body:SetAttribute("Creature", "Copy")
	body.PrimaryPart = body:FindFirstChild("HumanoidRootPart") :: BasePart
	local humanoid = body:FindFirstChildOfClass("Humanoid") :: Humanoid
	humanoid.DisplayName = player.DisplayName
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	humanoid.BreakJointsOnDeath = false
	humanoid.RequiresNeck = false
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
	return body
end

-- context = {
--   getTargets: () -> { Player },
--   isAlone: (Player) -> boolean,
--   isSafe: (Vector3) -> boolean,
--   spawnPoints: { Vector3 },
--   onAppear: (Player wearing, Player near) -> (),
--   onCatch: (Player) -> (),
--   onReveal: (Player by) -> (),
-- }
function Copy.new(context)
	local self = setmetatable({}, Copy)
	self.context = context
	self.mode = "Hidden"
	self.model = nil
	self.root = nil
	self.mover = nil
	self.wearing = nil
	self.respawnAt = math.huge
	self.visibleSince = 0
	self.stunnedUntil = 0
	self.pauseUntil = 0
	self.speedBonus = 0
	return self
end

function Copy:Position(): Vector3?
	return if self.model and self.root then self.root.Position else nil
end

function Copy:IsCopy(model: Instance): boolean
	return self.model ~= nil and (model == self.model or model:IsDescendantOf(self.model))
end

function Copy:Wearing(): Player?
	return if self.model then self.wearing else nil
end

function Copy:_despawnModel(fade: boolean)
	local model = self.model
	self.model, self.root, self.mover = nil, nil, nil
	if not model then
		return
	end
	if not fade then
		model:Destroy()
		return
	end
	if model.PrimaryPart then
		model.PrimaryPart.Anchored = true
	end
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			TweenService:Create(part, TweenInfo.new(0.5), { Transparency = 1 }):Play()
		elseif part:IsA("Decal") then
			part.Transparency = 1
		end
	end
	task.delay(0.6, function()
		model:Destroy()
	end)
end

-- Puts a copy of `wearing` at `position`, facing `facing`.
function Copy:Appear(wearing: Player, position: Vector3, facing: Vector3?)
	self:_despawnModel(false)
	local model = buildCopyOf(wearing)
	local root = model.PrimaryPart :: BasePart
	local humanoid = model:FindFirstChildOfClass("Humanoid") :: Humanoid
	local height = humanoid.HipHeight + root.Size.Y / 2
	local at = Vector3.new(position.X, position.Y + height + 0.2, position.Z)
	model:PivotTo(if facing then CFrame.lookAt(at, Vector3.new(facing.X, at.Y, facing.Z)) else CFrame.new(at))
	model.Parent = workspace
	pcall(root.SetNetworkOwner, root, nil)
	self.model, self.root, self.wearing = model, root, wearing
	self.mover = Mover.new(humanoid, root, 5)
	self.visibleSince = os.clock()
end

function Copy:SetMode(mode: string)
	self.mode = mode
	if mode == "Hidden" then
		self:_despawnModel(true)
		self.respawnAt = math.huge
	elseif mode == "Stalk" and not self.model then
		self.respawnAt = os.clock() + 3
	elseif mode == "Hunt" then
		self.speedBonus = 0
		if not self.model then
			self.respawnAt = os.clock()
		end
	end
end

-- Slips back into the fog and comes back later.
function Copy:Vanish(delaySeconds: number?)
	self:_despawnModel(true)
	local range = CONFIG.respawnDelay
	self.respawnAt = os.clock() + (delaySeconds or math.random(range[1], range[2]))
end

-- A handshake was offered to it. It can't answer.
function Copy:Reveal(by: Player)
	if not self.model then
		return
	end
	self.context.onReveal(by)
	if self.mode == "Hunt" then
		self:Stun(CONFIG.revealStun)
	else
		self:Vanish(CONFIG.revealCooldown)
	end
end

function Copy:Stun(seconds: number)
	self.stunnedUntil = os.clock() + seconds
end

function Copy:AddSpeed(amount: number)
	self.speedBonus += amount
end

function Copy:_reachable(player: Player): BasePart?
	local root = rootOf(player)
	if root and not self.context.isSafe(root.Position) then
		return root
	end
	return nil
end

function Copy:_spawnNear(): boolean
	local targets = self.context.getTargets()
	if #targets == 0 then
		return false
	end
	local target = targets[math.random(#targets)]
	local root = self:_reachable(target)
	if not root then
		return false
	end
	-- Prefer someone else's face, so it looks like a friend walking up.
	local others = {}
	for _, player in Players:GetPlayers() do
		if player ~= target and player.Character then
			table.insert(others, player)
		end
	end
	local wearing = if #others > 0 then others[math.random(#others)] else target

	local best, bestScore = nil, math.huge
	local want = (CONFIG.appearDistance[1] + CONFIG.appearDistance[2]) / 2
	for _, point in self.context.spawnPoints do
		local distance = ((point - root.Position) * Vector3.new(1, 0, 1)).Magnitude
		if distance >= CONFIG.appearDistance[1] and distance <= CONFIG.appearDistance[2] and not self.context.isSafe(point) then
			local score = math.abs(distance - want) + math.random() * 10
			if score < bestScore then
				best, bestScore = point, score
			end
		end
	end
	if not best then
		return false
	end
	self:Appear(wearing, best, root.Position)
	self.context.onAppear(wearing, target)
	return true
end

function Copy:_catch(player: Player)
	self.context.onCatch(player)
	self.pauseUntil = os.clock() + CONFIG.pauseAfterCatch
	if self.mode == "Stalk" then
		-- Its trick worked; it melts away to try again elsewhere.
		task.delay(1.5, function()
			if self.mode == "Stalk" then
				self:Vanish()
			end
		end)
	end
end

function Copy:Update(dt: number)
	local now = os.clock()
	if self.mode == "Hidden" then
		return
	end
	if not self.model then
		if now >= self.respawnAt then
			if not self:_spawnNear() then
				self.respawnAt = now + 2
			end
		end
		return
	end
	if now < self.stunnedUntil or now < self.pauseUntil then
		self.mover:Stop()
		return
	end

	local targets = self.context.getTargets()
	local position = self.root.Position
	local nearest, nearestRoot, nearestDistance = nil, nil, math.huge
	local loner, lonerRoot, lonerDistance = nil, nil, math.huge
	for _, player in targets do
		local root = self:_reachable(player)
		if root then
			local distance = ((root.Position - position) * Vector3.new(1, 0, 1)).Magnitude
			if distance < nearestDistance then
				nearest, nearestRoot, nearestDistance = player, root, distance
			end
			if distance < lonerDistance and self.context.isAlone(player) then
				loner, lonerRoot, lonerDistance = player, root, distance
			end
		end
	end

	if self.mode == "Hunt" then
		if nearest and nearestRoot then
			if nearestDistance <= CONFIG.catchDistance then
				self:_catch(nearest)
			else
				self.mover:Step(dt, nearestRoot.Position, CONFIG.huntSpeed + self.speedBonus)
			end
		else
			self.mover:Stop()
		end
		return
	end

	-- Stalk
	if now - self.visibleSince > CONFIG.lingerTime then
		self:Vanish()
		return
	end
	if loner and lonerRoot then
		if lonerDistance <= CONFIG.catchDistance then
			self:_catch(loner)
		else
			self.mover:Step(dt, lonerRoot.Position, CONFIG.stalkSpeed)
		end
	elseif nearest and nearestRoot then
		if nearestDistance > CONFIG.followDistance then
			self.mover:Step(dt, nearestRoot.Position, CONFIG.stalkSpeed * 0.8)
		else
			self.mover:Stop()
			self.root.CFrame = CFrame.lookAt(position, Vector3.new(nearestRoot.Position.X, position.Y, nearestRoot.Position.Z))
		end
	else
		self.mover:Stop()
	end
end

function Copy:Destroy()
	self.mode = "Destroyed"
	self:_despawnModel(false)
end

return Copy
