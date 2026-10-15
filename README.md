# The Hollow Pines

A Roblox multiplayer survival-horror mystery for ages 8–16. A school bus crashes in
a storm, the driver is gone, and something tall is watching from the trees.
Atmosphere, suspense and teamwork over gore: nobody dies, caught players are
"downed" and teammates help them up.

This repository is the full source for **Chapter 1, "The Storm"** and **Chapter 2,
"The Ranger"**, written in Luau and synced into Roblox Studio with [Rojo](https://rojo.space).

## What's in Chapter 1

Bus crash intro → empty driver's seat → emergency kit (flashlights) → footprint
trail and the first sighting of **The Watcher** → the ranger station → find three
fuses and restore power → solve the radio channel puzzle (a **Mimic** teaser on
the radio and at the tree line) → read the trail map → chase to the bridge → the
disturbing photograph ending → rewards.

## What's in Chapter 2

Unlocked by escaping Chapter 1. The empty rescue truck → a flooded campground →
the lit camp office, where **The Ranger** appears: a lantern-carrying patroller
who hunts by sound → whistles for everyone (blow one to lure him) → four torn map
pieces hold the boathouse padlock code → the flare gun → climb the lookout tower
and fire the flare while he guards the ladder → run for the helicopter → another
photograph. Sprinting and splashing are loud; standing still in a tent hides you.

Systems: fear, sprint/stamina, downed & revive, equipment (flashlight, lantern,
walkie, camera, calming flask, whistle), noise and hiding, XP and levels, Embers economy, shop, pets, daily
quests, achievements (with optional badges), lobby chapter select and matchmaking, session-locked
saves, accessibility settings, game passes and developer products.

## Quick start

1. Install [Aftman](https://github.com/LPGhatguy/aftman), then run `aftman install`
   in this folder (installs the pinned Rojo and Lune).
2. Install the Rojo plugin in Roblox Studio.
3. Run `rojo serve`, open a new Baseplate in Studio, delete the Baseplate part,
   and connect the Rojo plugin.
4. Press Play. The default project runs **Solo** mode: Chapter 1 starts as soon as
   you spawn. To play Chapter 2, serve `solo-chapter2.project.json` instead
   (`rojo serve solo-chapter2.project.json`). Enable *Game Settings → Security → Studio Access to API Services*
   to test saving.

Full setup, publishing and monetization steps are in [`docs/`](docs):

| Doc | What it covers |
| --- | --- |
| [GAME_DESIGN.md](docs/GAME_DESIGN.md) | Pillars, story, creatures, systems, tuning |
| [ARCHITECTURE.md](docs/ARCHITECTURE.md) | Folder layout, services, remotes, data flow |
| [SETUP.md](docs/SETUP.md) | Local development, Studio testing, adding assets |
| [DEPLOYMENT.md](docs/DEPLOYMENT.md) | Publishing the lobby and chapter places |
| [MONETIZATION.md](docs/MONETIZATION.md) | Passes, products, prices, policy notes |
| [TESTING.md](docs/TESTING.md) | Automated tests and the manual playtest checklist |
| [ROADMAP.md](docs/ROADMAP.md) | Phased plan for Chapters 3–4 and live updates |

## Tests

```sh
lune run tests/run
```

Compiles every Luau file and runs the unit specs for the pure game logic.
