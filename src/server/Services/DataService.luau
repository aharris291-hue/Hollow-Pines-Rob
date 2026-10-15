-- Loads, caches, replicates and saves player profiles.
--
-- Saves use UpdateAsync with a session lock so a player teleporting between the
-- lobby and a chapter server can never have two servers writing the same save.
-- In Studio without API access the game still runs; data just is not saved.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)
local DataTemplate = require(Shared.Config.DataTemplate)
local TableUtil = require(Shared.Util.TableUtil)
local Signal = require(Shared.Util.Signal)
local Net = require(Shared.Util.Net)

local DataService = {}

DataService.ProfileLoaded = Signal.new() -- (player, data)

local MAX_RECEIPTS_KEPT = 100

local store: DataStore?
local profiles: { [Player]: any } = {}
local savable: { [Player]: boolean } = {}
local replicateQueued: { [Player]: boolean } = {}

local function keyFor(player: Player): string
	return "player_" .. player.UserId
end

local function retry<T>(label: string, fn: () -> T): (boolean, T?)
	-- Studio usually fails because API access is off; fail fast so testing stays quick.
	local attempts = if RunService:IsStudio() then 1 else GameConfig.Data.MaxRetries
	for attempt = 1, attempts do
		local ok, result = pcall(fn)
		if ok then
			return true, result
		end
		warn(string.format("[DataService] %s failed (attempt %d): %s", label, attempt, tostring(result)))
		task.wait(math.min(2 ^ attempt, 16))
	end
	return false, nil
end

local function tryLoad(player: Player): (string, any?)
	if not store then
		return "nostore", nil
	end
	local lockedElsewhere = false
	local ok, record = retry("load " .. player.UserId, function()
		lockedElsewhere = false
		return store:UpdateAsync(keyFor(player), function(old)
			old = old or { Data = TableUtil.deepCopy(DataTemplate) }
			local lock = old.Lock
			local now = os.time()
			if lock and lock.JobId ~= game.JobId and now - lock.Time < GameConfig.Data.SessionLockTimeout then
				lockedElsewhere = true
				return nil -- cancel the write; another server still owns this save
			end
			old.Lock = { JobId = game.JobId, Time = now }
			return old
		end)
	end)
	if not ok then
		return "error", nil
	end
	if lockedElsewhere then
		return "locked", nil
	end
	return "ok", record
end

local function load(player: Player)
	local status, record = tryLoad(player)
	-- The previous server usually releases the lock a few seconds after a teleport.
	local waited = 0
	while status == "locked" and waited < 20 and player.Parent do
		task.wait(4)
		waited += 4
		status, record = tryLoad(player)
	end
	if status == "locked" and store then
		warn("[DataService] taking over a stale session lock for " .. player.UserId)
		local ok, stolen = retry("steal lock " .. player.UserId, function()
			return store:UpdateAsync(keyFor(player), function(old)
				old = old or { Data = TableUtil.deepCopy(DataTemplate) }
				old.Lock = { JobId = game.JobId, Time = os.time() }
				return old
			end)
		end)
		status = if ok then "ok" else "error"
		record = stolen
	end

	if not player.Parent then
		return
	end

	local data
	if status == "ok" and record then
		data = TableUtil.reconcile(record.Data or {}, DataTemplate)
		savable[player] = true
	else
		if status == "error" then
			warn("[DataService] could not load " .. player.UserId .. "; this session will not save")
		end
		data = TableUtil.deepCopy(DataTemplate)
		savable[player] = false
	end

	profiles[player] = data
	player:SetAttribute("Level", data.Level)
	DataService.ProfileLoaded:Fire(player, data)
	DataService:Replicate(player)
end

local function save(player: Player, release: boolean): boolean
	local data = profiles[player]
	if not data or not savable[player] or not store then
		return false
	end
	local ok = retry("save " .. player.UserId, function()
		store:UpdateAsync(keyFor(player), function(old)
			old = old or {}
			local lock = old.Lock
			if lock and lock.JobId ~= game.JobId then
				-- Another server took over this save; never overwrite its newer data.
				return nil
			end
			old.Data = data
			old.Lock = if release then nil else { JobId = game.JobId, Time = os.time() }
			return old
		end)
	end)
	return ok
end

function DataService:Init()
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(GameConfig.Data.StoreName)
	end)
	if ok then
		store = result
	else
		warn("[DataService] DataStores unavailable (enable Studio API access to test saving): " .. tostring(result))
	end

	Net.Function("GetProfile").OnServerInvoke = function(player)
		return DataService:Snapshot(player)
	end
end

function DataService:Start()
	Players.PlayerAdded:Connect(load)
	for _, player in Players:GetPlayers() do
		task.spawn(load, player)
	end

	Players.PlayerRemoving:Connect(function(player)
		save(player, true)
		profiles[player] = nil
		savable[player] = nil
		replicateQueued[player] = nil
	end)

	task.spawn(function()
		while true do
			task.wait(GameConfig.Data.AutosaveInterval)
			for player in profiles do
				task.spawn(save, player, false)
			end
		end
	end)

	game:BindToClose(function()
		if RunService:IsStudio() and not store then
			return
		end
		local pending = 0
		for player in profiles do
			pending += 1
			task.spawn(function()
				save(player, true)
				pending -= 1
			end)
		end
		local deadline = os.clock() + 25
		while pending > 0 and os.clock() < deadline do
			task.wait(0.2)
		end
	end)
end

function DataService:Get(player: Player)
	return profiles[player]
end

function DataService:WaitFor(player: Player, timeout: number?)
	local deadline = os.clock() + (timeout or 30)
	while not profiles[player] and player.Parent and os.clock() < deadline do
		task.wait(0.1)
	end
	return profiles[player]
end

-- Mutate a profile through here so the client is always told about it.
function DataService:Update(player: Player, mutator: (any) -> ())
	local data = profiles[player]
	if not data then
		return false
	end
	mutator(data)
	self:Replicate(player)
	return true
end

-- The client copy leaves out receipt history.
function DataService:Snapshot(player: Player)
	local data = profiles[player]
	if not data then
		return nil
	end
	local copy = table.clone(data)
	copy.Purchases = nil
	copy.PurchaseOrder = nil
	copy.IsVIP = player:GetAttribute("VIP") == true
	return copy
end

-- Batches replication to one send per frame however many changes happen.
function DataService:Replicate(player: Player)
	if replicateQueued[player] then
		return
	end
	replicateQueued[player] = true
	task.defer(function()
		replicateQueued[player] = nil
		if player.Parent and profiles[player] then
			Net.Event("ProfileUpdated"):FireClient(player, self:Snapshot(player))
		end
	end)
end

-- Used by purchases, which must be stored before Roblox is told they succeeded.
function DataService:SaveNow(player: Player): boolean
	if not savable[player] then
		-- Without a working DataStore nothing can be stored, so the purchase is
		-- only safe to grant in Studio test sessions.
		return RunService:IsStudio()
	end
	return save(player, false)
end

function DataService:RecordReceipt(data, receiptId: string)
	data.Purchases[receiptId] = true
	table.insert(data.PurchaseOrder, receiptId)
	while #data.PurchaseOrder > MAX_RECEIPTS_KEPT do
		local oldest = table.remove(data.PurchaseOrder, 1)
		data.Purchases[oldest] = nil
	end
end

return DataService
