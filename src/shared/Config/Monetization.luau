-- Game passes and developer products. Ids are 0 until they are created on the
-- Creator Dashboard (docs/MONETIZATION.md lists each one with suggested prices).
-- A 0 id hides the offer in the shop so nothing broken is ever shown to players.

local Monetization = {}

Monetization.GamePasses = {
	VIP = {
		id = 0,
		name = "Pines VIP",
		description = "+25% Embers, Golden Beam, Ghost Pup pet and a VIP name tag.",
		suggestedRobux = 199,
	},
	SupporterPack = {
		id = 0,
		name = "Supporter Pack",
		description = "Thank you! A supporter badge and 1,000 Embers once.",
		suggestedRobux = 99,
		grantsEmbers = 1000,
	},
}

Monetization.Products = {
	EmbersSmall = { id = 0, name = "Pouch of Embers", embers = 500, suggestedRobux = 49 },
	EmbersMedium = { id = 0, name = "Jar of Embers", embers = 1200, suggestedRobux = 99 },
	EmbersLarge = { id = 0, name = "Chest of Embers", embers = 3000, suggestedRobux = 199 },
	-- Revive yourself instead of waiting for a teammate. Once per chapter, so it can
	-- never buy a full run.
	SecondWind = { id = 0, name = "Second Wind", revive = true, suggestedRobux = 25 },
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
