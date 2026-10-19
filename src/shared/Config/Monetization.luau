-- Game passes and developer products, created on the Creator Dashboard
-- (docs/MONETIZATION.md). suggestedRobux records the price set there; the
-- purchase prompt always shows Roblox's live price. A 0 id hides the offer.

local Monetization = {}

Monetization.GamePasses = {
	VIP = {
		id = 2037856885,
		name = "Pines VIP",
		description = "+25% Embers, Golden Beam, Ghost Pup pet and a VIP name tag.",
		suggestedRobux = 399,
	},
	SupporterPack = {
		id = 2040184509,
		name = "Supporter Pack",
		description = "Thank you! A supporter badge and 1,000 Embers once.",
		suggestedRobux = 199,
		grantsEmbers = 1000,
	},
}

Monetization.Products = {
	EmbersSmall = { id = 3720059261, name = "Pouch of Embers", embers = 500, suggestedRobux = 79 },
	EmbersMedium = { id = 3720059755, name = "Jar of Embers", embers = 1200, suggestedRobux = 179 },
	EmbersLarge = { id = 3720059989, name = "Chest of Embers", embers = 3000, suggestedRobux = 399 },
	-- Revive yourself instead of waiting for a teammate. Once per chapter, so it can
	-- never buy a full run.
	SecondWind = { id = 3720060191, name = "Second Wind", revive = true, suggestedRobux = 199 },
}

function Monetization.ProductById(productId: number)
	if productId == 0 then
		return nil
	end
	for key, product in Monetization.Products do
		if product.id == productId then
			return key, product
		end
	end
	return nil
end

function Monetization.PassById(passId: number)
	if passId == 0 then
		return nil
	end
	for key, pass in Monetization.GamePasses do
		if pass.id == passId then
			return key, pass
		end
	end
	return nil
end

return Monetization
