-- Embers: the one soft currency. Earned by playing, optionally bought, spent on
-- cosmetics and pets. Every change goes through here so it is logged once.

local AnalyticsService = game:GetService("AnalyticsService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)

local EconomyService = {}

local services

-- flow is "Source" or "Sink"; transactionType is an AnalyticsEconomyTransactionType name.
local function log(player: Player, flow: string, amount: number, balance: number, transactionType: string, sku: string?)
	pcall(function()
		AnalyticsService:LogEconomyEvent(player, Enum.AnalyticsEconomyFlowType[flow], "Embers", amount, balance, transactionType, sku)
	end)
end

function EconomyService:Init(registry)
	services = registry
end

-- `earned` rewards get the VIP bonus; purchased Embers never do.
function EconomyService:Add(player: Player, amount: number, reason: string, earned: boolean?): number
	if amount <= 0 then
		return 0
	end
	if earned and player:GetAttribute("VIP") then
		amount = math.floor(amount * GameConfig.Rewards.VIPEmberMultiplier)
	end
	local balance = 0
	services.DataService:Update(player, function(data)
		data.Embers += amount
		balance = data.Embers
	end)
	log(player, "Source", amount, balance, if earned then "Gameplay" else "IAP", reason)
	return amount
end

function EconomyService:CanAfford(player: Player, amount: number): boolean
	local data = services.DataService:Get(player)
	return data ~= nil and data.Embers >= amount
end

function EconomyService:Spend(player: Player, amount: number, sku: string): boolean
	if not self:CanAfford(player, amount) then
		return false
	end
	local balance = 0
	services.DataService:Update(player, function(data)
		data.Embers -= amount
		balance = data.Embers
	end)
	log(player, "Sink", amount, balance, "Shop", sku)
	return true
end

return EconomyService
