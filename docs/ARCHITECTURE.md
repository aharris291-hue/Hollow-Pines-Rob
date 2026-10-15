# Architecture

## Layout

```
default.project.json     Solo: one place, Chapter 1 starts on join (Studio testing)
lobby.project.json       Lobby place
chapter1.project.json    Chapter 1 place
src/
  shared/                ReplicatedStorage.Shared
    Config/              All tuning and content: GameConfig, Items, Quests, Achievements,
                         Creatures, Monetization, Assets, DataTemplate
    Util/                Net (remotes), Signal, TableUtil, RateLimit and the pure logic
                         modules FearMath, Progression, QuestLogic, PuzzleCode
  server/                ServerScriptService.Server
    init.server.luau     Bootstrap: chooses services for the place role, Init then Start
    EventBus.luau        Gameplay facts ("FuseInserted") that quests/achievements listen to
    Services/            One module per system (below)
    Creatures/           Watcher, Mimic, Ranger (stub), HollowOne (stub)
    World/               Builder helpers and the Chapter 1 greybox map
  client/                StarterPlayerScripts.Client
    init.client.luau     Bootstrap for controllers
    Controllers/         Data, Audio, Input, Atmosphere, Fear, UI, Cutscene
    UI/                  UIKit, Hud, Menus, Panels
tests/                   Lune test runner and specs
```

## Place roles

`ReplicatedStorage` carries a `PlaceRole` attribute set by the Rojo project. Once
place ids are filled into `GameConfig.Places`, the server uses `game.PlaceId`
instead. Roles:

- **Lobby**: common services + `LobbyService`, `MatchmakingService`.
- **Chapter1** and **Solo**: common services + `PlayerStateService`, `EquipmentService`, `FearService`, `CreatureService`, `OnboardingService`, `ChapterService`.

Common services: `DataService`, `EconomyService`, `ProgressionService`,
`InventoryService`, `MonetizationService`, `QuestService`, `AchievementService`,
`SettingsService`, `PetService`.

## Service contract

Each service is a ModuleScript table with optional `Init(self, services)` (wire
remotes, no yielding, no calls into other services) and `Start(self)` (spawned,
may loop). Services reach each other through the `services` table.

## Data flow

- The server is authoritative for everything: fear, currency, ownership, quest progress, puzzle answers.
- Clients only send requests (`BuyItem`, `EquipItem`, `ChangeSetting`, `SubmitRadioCode`...). Every handler type-checks its arguments, and spammable ones are rate-limited.
- Profiles change only through `DataService:Update`, which batches a `ProfileUpdated` push to the owner each frame.
- Fear, stamina, downed and escaped state are player attributes, so every client can show teammates' state without extra remotes.
- Gameplay code fires `EventBus` facts; `QuestService` and `AchievementService` turn them into progress, so new quests or achievements are config-only.

## Remotes

All remote names live in `src/shared/Util/Net.luau`. The server creates them on
boot; the client waits for them. Add a name there to add a remote.

## Saves

`DataService` stores `{ Data, Lock }` per player with `UpdateAsync`. A server
only loads a profile when no other server holds a fresh lock (it waits up to
20 s for the previous server after a teleport, then takes over a stale lock),
and only writes while it still owns the lock. `TableUtil.reconcile` fills new
template keys into old saves. Purchases are saved before Roblox is told they
were granted, and receipt ids are remembered.

## Replacing the greybox map

`World/Chapter1Map.luau` builds the map from code and returns references
(`DriverSeat`, `FuseBox`, `FuseSpots`, `ExitZone`, ...). To use a hand-built
map, build it in Studio and have `Build()` return the same references from it.
