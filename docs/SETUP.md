# Local setup

## Tools

- Roblox Studio with the Rojo plugin.
- [Aftman](https://github.com/LPGhatguy/aftman). `aftman install` installs the versions pinned in `aftman.toml` (Rojo 7.4.4, Lune 0.11.0).

## Run it in Studio

```sh
rojo serve                      # Solo mode (default.project.json)
rojo serve lobby.project.json   # to work on the lobby
```

Open a new Baseplate, delete the `Baseplate` part, connect the Rojo plugin, press
**Play**. For multiplayer use *Test → Clients and Servers* with 2–4 players.

To build a place file without Studio:

```sh
rojo build default.project.json -o HollowPines.rbxl
```

## Saving in Studio

Enable *Game Settings → Security → Enable Studio Access to API Services* (the place
must be published first). Without it the game runs normally; the output shows
that the session won't save.

## Assets (sound)

Every sound id in `src/shared/Config/Assets.luau` starts at `0` (silent). Pick
audio from the Creator Store or upload your own, then paste the ids. Suggested
sounds: steady rain loop, distant thunder, bus crash, slow heartbeat loop, a short
dissonant sting, a whisper, radio static, a generator hum, tense chase music,
camera shutter, UI click, reward chime. Captions are shown for all of them, so
the game is fully playable while they are 0.

## Tuning

All balance values are in `src/shared/Config/`. Common ones:

- Fear rates and thresholds: `GameConfig.Fear`
- Chase speed and stalking: `Creatures.Watcher`
- Rewards: `GameConfig.Rewards`, `Quests`, `Achievements`
- Prices: `Items`
