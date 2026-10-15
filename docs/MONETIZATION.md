# Monetization

Built for a young audience, so the rules are strict:

- **Nothing paid changes who survives.** Equipment is earned by levels only. The single gameplay purchase, Second Wind, is once per chapter and only gets a player back up.
- **No paid random items** (no loot boxes, no gacha).
- **Everything sold for Robux is also reachable by playing**, except VIP cosmetics.
- Prices are shown up front; purchases always go through Roblox's own prompt.

## Game passes

| Key | Suggested price | Grants |
| --- | --- | --- |
| `VIP` | 199 R$ | +25% Embers from play, Golden Beam, Ghost Pup pet, VIP attribute for a name tag |
| `SupporterPack` | 99 R$ | 1,000 Embers once, supporter attribute |

## Developer products

| Key | Suggested price | Grants |
| --- | --- | --- |
| `EmbersSmall` | 49 R$ | 500 Embers |
| `EmbersMedium` | 99 R$ | 1,200 Embers |
| `EmbersLarge` | 199 R$ | 3,000 Embers |
| `SecondWind` | 25 R$ | One self-revive, max once per chapter |

## Setup

1. Creator Dashboard → your experience → *Monetization* → *Passes* / *Developer Products*.
2. Create each item above (icon, name, price).
3. Paste the ids into `src/shared/Config/Monetization.luau`. An id of `0` hides the offer.

## How purchases are processed

`MonetizationService` sets `MarketplaceService.ProcessReceipt`. It grants the
product, records the receipt id in the profile, **saves**, and only then returns
`PurchaseGranted`. If the save fails it rolls back and returns `NotProcessedYet`,
so Roblox retries later. Already-recorded receipts return `PurchaseGranted`
without granting again. Every Ember source and sink is logged to Roblox
Analytics economy events.

## Earn rates (for balancing)

A first clear pays roughly 150 + 250 (first clear) Embers, plus level-up and
achievement Embers. A typical repeat clear with daily quests is about 300–450 Embers,
so a 400–900 Ember cosmetic takes one to three sessions.
