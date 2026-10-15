-- Buying and equipping. All checks happen here; the client only asks.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Items = require(Shared.Config.Items)
local Net = require(Shared.Util.Net)
local RateLimit = require(Shared.Util.RateLimit)

local InventoryService = {}

local services
local limiter = RateLimit.new(0.3)

local function toast(player: Player, text: string, kind: string?)
	Net.Event("Toast"):FireClient(player, text, kind or "Info")
end

function InventoryService:Init(registry)
	services = registry

	Net.Event("BuyItem").OnServerEvent:Connect(function(player, itemId)
		if type(itemId) == "string" and limiter:Allow(player) then
			self:Buy(player, itemId)
		end
	end)

	Net.Event("EquipItem").OnServerEvent:Connect(function(player, itemId)
		if type(itemId) == "string" and limiter:Allow(player) then
			self:Equip(player, itemId)
		end
	end)
end

function InventoryService:Owns(player: Player, itemId: string): boolean
	local data = services.DataService:Get(player)
	return data ~= nil and data.Owned[itemId] == true
end

function InventoryService:Grant(player: Player, itemId: string)
	services.DataService:Update(player, function(data)
		data.Owned[itemId] = true
	end)
end

function InventoryService:Buy(player: Player, itemId: string): boolean
	local item = Items.Find(itemId)
	local category = Items.Category(itemId)
	if not item or category == "Equipment" then
		return false -- equipment comes from levels, never from purchases
	end
	if self:Owns(player, itemId) then
		toast(player, "You already own " .. item.name)
		return false
	end
	if item.vipOnly or item.achievement or (item.price or 0) <= 0 then
		toast(player, item.name .. " can't be bought")
		return false
	end
	if not services.EconomyService:Spend(player, item.price, itemId) then
		toast(player, "Not enough Embers", "Error")
		return false
	end
	self:Grant(player, itemId)
	toast(player, "Bought " .. item.name .. "!", "Success")
	return true
end

function InventoryService:Equip(player: Player, itemId: string): boolean
	local data = services.DataService:Get(player)
	if not data then
		return false
	end
	-- An empty pet id unequips the current pet.
	if itemId == "" then
		services.DataService:Update(player, function(d)
			d.EquippedPet = ""
		end)
		services.PetService:Refresh(player)
		return true
	end
	if not data.Owned[itemId] then
		return false
	end

	local category = Items.Category(itemId)
	local item = Items.Find(itemId)
	services.DataService:Update(player, function(d)
		if category == "Equipment" then
			d.Loadout[item.slot] = itemId
		elseif category == "Pets" then
			d.EquippedPet = itemId
		elseif item.kind == "BeamColor" then
			d.EquippedBeam = itemId
		elseif item.kind == "Title" then
			d.EquippedTitle = if d.EquippedTitle == itemId then "" else itemId
		end
	end)

	if category == "Pets" then
		services.PetService:Refresh(player)
	elseif category == "Equipment" and services.EquipmentService then
		services.EquipmentService:RefreshLoadout(player)
	elseif item.kind == "BeamColor" and services.EquipmentService then
		services.EquipmentService:ApplyCosmetics(player)
	end
	if item.kind == "Title" then
		player:SetAttribute("Title", if data.EquippedTitle ~= "" then Items.Cosmetics[data.EquippedTitle].name else nil)
	end
	return true
end

return InventoryService
