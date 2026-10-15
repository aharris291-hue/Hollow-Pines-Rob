-- Fastest escapes. Every chapter place saves each player's personal best in
-- their profile and posts it to that chapter's OrderedDataStore; the lobby
-- shows the top times on a board by the campfire, one chapter at a time.
-- Without DataStores (Studio with API access off) personal bests still work for
-- the session and the board says the times appear once the game is published.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)
local Chapters = require(Shared.Config.Chapters)
local BestTimes = require(Shared.Util.BestTimes)
local World = script.Parent.Parent:WaitForChild("World")
local Builder = require(World.Builder)

local LeaderboardService = {}

local CONFIG = GameConfig.Leaderboards
local WOOD = Color3.fromRGB(92, 64, 44)

local services
local stores: { [number]: OrderedDataStore } = {}
local names: { [number]: string } = {}

local function storeFor(chapterId: number): OrderedDataStore?
	if stores[chapterId] then
		return stores[chapterId]
	end
	local ok, store = pcall(DataStoreService.GetOrderedDataStore, DataStoreService, CONFIG.StoreName .. chapterId)
	if ok then
		stores[chapterId] = store
		return store
	end
	return nil
end

local function nameOf(userId: number): string
	if names[userId] then
		return names[userId]
	end
	local ok, name = pcall(Players.GetNameFromUserIdAsync, Players, userId)
	names[userId] = if ok and name then name else "Camper"
	return names[userId]
end

-- Records a finished run. Returns whether it beat the player's best, and the
-- best time (in seconds) after this run.
function LeaderboardService:Submit(player: Player, chapterId: number, seconds: number): (boolean, number?)
	local time = BestTimes.sanitize(seconds)
	local data = services.DataService:Get(player)
	if not time or not data then
		return false, nil
	end
	local key = tostring(chapterId)
	local previous = data.BestTimes[key]
	if not BestTimes.isBetter(previous, time) then
		return false, previous
	end
	services.DataService:Update(player, function(d)
		d.BestTimes[key] = time
	end)
	task.spawn(function()
		local store = storeFor(chapterId)
		if not store then
			return
		end
		local ok, err = pcall(store.UpdateAsync, store, tostring(player.UserId), function(old)
			-- Keep whichever is faster, in case another server posted first.
			return if old == nil or time < old then time else nil
		end)
		if not ok then
			warn("[Leaderboard] couldn't post a time: " .. tostring(err))
		end
	end)
	return true, time
end

local function fetchTop(chapterId: number): { BestTimes.Entry }?
	local store = storeFor(chapterId)
	if not store then
		return nil
	end
	local ok, pages = pcall(store.GetSortedAsync, store, true, CONFIG.Size)
	if not ok then
		return nil
	end
	local entries = {}
	for _, row in (pages :: DataStorePages):GetCurrentPage() do
		local userId = tonumber(row.key)
		if userId then
			table.insert(entries, { name = nameOf(userId), seconds = row.value })
		end
	end
	return entries
end

local function buildBoard(): (TextLabel, TextLabel)
	local model = Instance.new("Model")
	model.Name = "Leaderboard"
	local at = Vector3.new(24, 0, 2)
	local facing = CFrame.lookAt(at, Vector3.new(0, 0, 0))
	Builder.part(model, "PostL", Vector3.new(1, 12, 1), facing * CFrame.new(-7.5, 6, 0), WOOD, Enum.Material.Wood)
	Builder.part(model, "PostR", Vector3.new(1, 12, 1), facing * CFrame.new(7.5, 6, 0), WOOD, Enum.Material.Wood)
	local board = Builder.part(model, "Board", Vector3.new(14, 9, 0.6), facing * CFrame.new(0, 7, 0), Color3.fromRGB(58, 44, 34), Enum.Material.Wood)
	local light = Instance.new("SpotLight")
	light.Face = Enum.NormalId.Front
	light.Range = 14
	light.Brightness = 1.5
	light.Color = Color3.fromRGB(255, 200, 140)
	light.Parent = board

	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.LightInfluence = 0.2
	gui.Parent = board
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -40, 0, 70)
	title.Position = UDim2.fromOffset(20, 14)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.Merriweather
	title.TextScaled = true
	title.TextColor3 = Color3.fromRGB(255, 186, 102)
	title.Parent = gui
	local list = Instance.new("TextLabel")
	list.Size = UDim2.new(1, -60, 1, -110)
	list.Position = UDim2.fromOffset(30, 96)
	list.BackgroundTransparency = 1
	list.Font = Enum.Font.GothamMedium
	list.TextSize = 26
	list.TextXAlignment = Enum.TextXAlignment.Left
	list.TextYAlignment = Enum.TextYAlignment.Top
	list.TextColor3 = Color3.fromRGB(240, 228, 200)
	list.Parent = gui
	model.Parent = workspace
	return title, list
end

function LeaderboardService:Init(registry)
	services = registry
end

function LeaderboardService:Start()
	if ReplicatedStorage:GetAttribute("PlaceRole") ~= "Lobby" then
		return
	end
	local title, list = buildBoard()
	local boards: { [number]: { BestTimes.Entry }? } = {}
	local loaded = false

	task.spawn(function()
		while true do
			for _, chapter in Chapters do
				boards[chapter.id] = fetchTop(chapter.id)
			end
			loaded = true
			task.wait(CONFIG.RefreshInterval)
		end
	end)

	while true do
		for _, chapter in Chapters do
			title.Text = string.format("Fastest escapes · Chapter %d: %s", chapter.id, chapter.name)
			local entries = boards[chapter.id]
			if not loaded then
				list.Text = "Counting up the times..."
			elseif entries == nil then
				list.Text = "Times show up here once the game is published."
			elseif #entries == 0 then
				list.Text = "No escapes yet. Be the first!"
			else
				list.Text = table.concat(BestTimes.lines(entries, CONFIG.Size), "\n")
			end
			task.wait(CONFIG.PageSeconds)
		end
	end
end

return LeaderboardService
