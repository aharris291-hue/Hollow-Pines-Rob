# Deployment

Hollow Pines ships as **one place**. The lobby file holds every chapter: when a
group presses Play, the lobby reserves a private server of the same place and
sends the chapter number in the teleport data. That server waits for its first
player, runs the chapter, and sends everyone back to a public (lobby) server at
the end. No place ids need filling in.

## 1. Publish

1. Build the place file: `rojo build lobby.project.json -o HollowPines.rbxl`.
2. Open it in Studio, *File → Publish to Roblox*, and create a new experience
   (or publish over the experience's start place).
3. That's all. Players' saves, best times and purchases are shared by every
   server of the place.

### Optional: separate chapter places

`chapter1-4.project.json` still build one place per chapter. To use them, add
four places to the experience, publish each chapter file into its place, put
the ids in `GameConfig.Places` and republish all five. Any chapter id left at
0 falls back to the one-place mode above.

## 2. Experience settings

- *Permissions*: Public when ready; *Avatar*: R15.
- *Security*: enable API Services (saves) and allow third-party teleports only if you add other games later (not needed).
- *Server size*: 20 for the place (chapter groups are capped at 6 by `GameConfig.Party.MaxPlayers`). With separate chapter places, set those to 6.
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
- [ ] Passes/products created and tested with a test purchase in Studio
- [ ] Thumbnails, icon and description uploaded
- [ ] `GameConfig.Version` bumped and tagged in git
