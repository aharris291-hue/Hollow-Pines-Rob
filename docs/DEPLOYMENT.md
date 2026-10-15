# Deployment

Hollow Pines ships as one experience with three places: the **Lobby** (start
place), **Chapter 1** and **Chapter 2**.

## 1. Create the places

1. Build the place files:
   ```sh
   rojo build lobby.project.json -o Lobby.rbxl
   rojo build chapter1.project.json -o Chapter1.rbxl
   rojo build chapter2.project.json -o Chapter2.rbxl
   ```
2. Open `Lobby.rbxl` in Studio, *File → Publish to Roblox* as a new experience. This is the start place.
3. On the Creator Dashboard, open the experience → *Places* → *Add place*, then open `Chapter1.rbxl` and publish it to that new place. Do the same for `Chapter2.rbxl`.
4. Copy the place ids into `src/shared/Config/GameConfig.luau`:
   ```lua
   GameConfig.Places = { Lobby = 1234567890, Chapter1 = 2345678901, Chapter2 = 3456789012 }
   ```
5. Rebuild and republish all three places (every place needs the same ids).

## 2. Experience settings

- *Permissions*: Public when ready; *Avatar*: R15.
- *Security*: enable API Services (saves) and allow third-party teleports only if you add other games later (not needed).
- *Places → Chapter 1 and Chapter 2 → Server size*: 6 (matches `GameConfig.Party.MaxPlayers`). Lobby: 20–30.
- Complete the **Experience Questionnaire** honestly. The game has mild fear and suspense with no blood or violence, which usually lands in the "Mild" maturity band; confirm the label Roblox assigns.

## 3. Monetization ids

Create the passes and products from [MONETIZATION.md](MONETIZATION.md), paste the
ids into `src/shared/Config/Monetization.luau`, rebuild and republish. Offers with
id `0` stay hidden.

## 4. Badges (optional)

Create badges for the achievements you want, paste ids into
`src/shared/Config/Achievements.luau` (`badgeId`).

## 5. Release checklist

- [ ] `lune run tests/run` passes
- [ ] Manual playtest checklist in [TESTING.md](TESTING.md) done with 1 and 3+ players
- [ ] Sound ids filled in `Assets.luau`
- [ ] Place ids set, both places republished from the same commit
- [ ] Passes/products created and tested with a test purchase in Studio
- [ ] Thumbnails, icon and description uploaded
- [ ] `GameConfig.Version` bumped and tagged in git
