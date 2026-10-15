-- Game passes and developer products.
-- ProcessReceipt only reports PurchaseGranted after the grant is saved, and
-- receipt ids are remembered so a retried receipt is never granted twice.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Monetization = require(Shared.Config.Monetization)
local Items = require(Shared.Config.Items)
local Net = require(Shared.Util.Net)

local MonetizationService = {}

local services
local passCache: { [Player]: { [string]: boolean } } = {}

local function ownsPass(player: Player, key: string): boolean
	local pass = Monetization.GamePasses[key]
	if not pass or pass.id == 0 then
		return false
	end
	passCache[player] = passCache[player] or {}
	if passCache[player][key] == nil then
		local ok, owns = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, pass.id)
		if not ok then
			return false -- try again next time instead of caching a failure
		end
		passCache[player][key] = owns
	end
	return passCache[player][key]
end

local function applyPasses(player: Player)
	local data = services.DataService:WaitFor(player)
	if not data then
		return
	end

	if ownsPass(player, "VIP") then
		player:SetAttribute("VIP", true)
		for id, item in Items.Cosmetics do
			if item.vipOnly then
				services.InventoryService:Grant(player, id)
			end
		end
		for id, item in Items.Pets do
			if item.vipOnly then
				services.InventoryService:Grant(player, id)
			end
		end
	end

	if ownsPass(player, "SupporterPack") and not data.SupporterGranted then
		services.DataService:Update(player, function(d)
			d.SupporterGranted = true
		end)
		services.EconomyService:Add(player, Monetization.GamePasses.SupporterPack.grantsEmbers, "SupporterPack", false)
		player:SetAttribute("Supporter", true)
	elseif data.SupporterGranted then
		player:SetAttribute("Supporter", true)
	end

	services.DataService:Replicate(player)
end

local function processReceipt(receipt)
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local data = services.DataService:WaitFor(player, 15)
	if not data then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	if data.Purchases[receipt.PurchaseId] then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	local key, product = Monetization.ProductById(receipt.ProductId)
	if not key then
		warn("[Monetization] unknown product " .. tostring(receipt.ProductId))
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	-- Grant and record together, then save before acknowledging.
	services.DataService:Update(player, function(d)
		if product.embers then
			d.Embers += product.embers
		end
		if product.revive then
			d.SecondWinds += 1
		end
		services.DataService:RecordReceipt(d, receipt.PurchaseId)
	end)

	if not services.DataService:SaveNow(player) then
		-- Roll back so the retried receipt grants exactly once.
		services.DataService:Update(player, function(d)
			if product.embers then
				d.Embers -= product.embers
			end
			if product.revive then
				d.SecondWinds -= 1
			end
			d.Purchases[receipt.PurchaseId] = nil
			local index = table.find(d.PurchaseOrder, receipt.PurchaseId)
			if index then
				table.remove(d.PurchaseOrder, index)
			end
		end)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	if product.embers then
		Net.Event("Toast"):FireClient(player, "+" .. product.embers .. " Embers. Thank you!", "Success")
	end
	if product.revive then
		Net.Event("Toast"):FireClient(player, "Second Wind ready", "Success")
		if services.PlayerStateService then
			services.PlayerStateService:TryUseSecondWind(player)
		end
	end
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

function MonetizationService:Init(registry)
	services = registry
	MarketplaceService.ProcessReceipt = processReceipt
end

function MonetizationService:Start()
	Players.PlayerAdded:Connect(applyPasses)
	for _, player in Players:GetPlayers() do
		task.spawn(applyPasses, player)
	end
	Players.PlayerRemoving:Connect(function(player)
		passCache[player] = nil
	end)

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		if not purchased then
			return
		end
		local key = Monetization.PassById(passId)
		if key then
			passCache[player] = passCache[player] or {}
			passCache[player][key] = true
			applyPasses(player)
			Net.Event("Toast"):FireClient(player, "Thank you for supporting Hollow Pines!", "Success")
		end
	end)
end

function MonetizationService:IsVIP(player: Player): boolean
	return player:GetAttribute("VIP") == true
end

return MonetizationService
