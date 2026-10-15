# Game design

## Audience and tone

Ages 8–16. Scary through atmosphere, sound, darkness and uncertainty, never gore.
No blood, no deaths: being caught "downs" a player, a teammate helps them up, or
they wake at the last checkpoint. Story text is short and readable aloud.

## Pillars

| Pillar | How Chapter 1 delivers it |
| --- | --- |
| You Are Never Safe | Fear rises in the dark and alone; The Watcher relocates out of sight and creeps closer. |
| The Forest Knows More Than You | Notes, the ranger's log and the photograph hint at more than they explain. |
| Trust Is Dangerous | The Mimic calls players by name in a friend's voice and stands at the tree line wearing a teammate's avatar. |
| Survival Through Teamwork | Teammates calm fear, lanterns calm everyone nearby, only teammates can revive, fuses and clues are spread out. |
| Mystery Over Monsters | The Watcher never attacks until the finale; most of the chapter is investigation. |

## Chapter 1: The Storm (about 15–20 minutes)

1. **Intro.** Title card, rain on the bus, the driver takes a shortcut, crash.
2. **The driver.** His seat is empty, the belt cut, the door forced from outside.
3. **Emergency kit.** Hands every player their loadout (flashlight by default).
4. **Footprints.** A trail into the woods. Halfway along, lightning shows The Watcher standing in the trees. Looking at it makes it vanish.
5. **Ranger station.** Dark. Three fuses are hidden at random among six props in the clearing. Inserting them powers the lights, makes the station a safe zone and recharges batteries.
6. **Radio puzzle.** The emergency channel is split across three check-in sheets on different walls (random per server). Tuning it brings Ranger Hale's warning: stay on the road, never answer a friend's voice from the trees. Then a voice uses a player's name.
7. **The Mimic teaser.** It whispers names from behind players (with directional captions) and shows a still copy of a teammate at the tree line that vanishes when approached.
8. **Map table.** Reveals the old service road to the bridge.
9. **Chase.** Leaving the station triggers The Watcher to hunt. Reach the bridge and Route 9. It pauses after each catch so others can escape, backs off if everyone is down, and speeds up if the chase drags on.
10. **The photograph.** A polaroid of the group beside the crashed bus, taken tonight, with something tall between the trees behind them.

## Creatures

| Creature | Chapter 1 role | Behaviour |
| --- | --- | --- |
| The Watcher | Antagonist | Stalks from the tree line, repositions where nobody is looking, vanishes after eye contact, raises fear nearby. Hunts in the finale. A camera flash makes it look away. |
| The Mimic | Teaser | Voice lines using players' names; a decoy wearing a teammate's avatar. Harmless in Chapter 1. |
| The Ranger | Voice on the radio | Becomes a sound-hunting patroller in Chapter 2. |
| The Hollow One | Unseen | The secret at the centre of the forest, Chapter 4. |

## Systems

- **Fear (0–100).** Rises in darkness, alone, and near The Watcher; falls with a light, near teammates, near a teammate's lantern, and inside the powered station. Tiers: Calm, Uneasy (35), Scared (65), Panicked (90). Panicked slows walking. Effects: vignette, desaturation, heartbeat, light shake. Tuning in `src/shared/Config/GameConfig.luau`.
- **Movement.** Walk 12, sprint 20 with stamina.
- **Downed and revive.** Caught players drop to the ground; a teammate holds the prompt for 3 s to help them up, otherwise they wake at the checkpoint after 25 s.
- **Equipment.** Two slots (Light, Tool). Flashlight (Lv1), Walkie ping (Lv2), Calming flask (Lv3), Storm lantern (Lv4), Instant camera (Lv6). Unlocked by level, never sold.
- **Progression.** XP from the chapter and quests, curve `100 × level^1.4`, max level 50, Embers on every level and more every fifth.
- **Economy.** One currency, Embers: earned from play, quests, achievements and levels; spent on beam colours, titles and pets.
- **Pets.** Cosmetic companions that float beside you.
- **Quests.** Three daily quests per UTC day, same on every server.
- **Achievements.** Eight, from lifetime stats, some with title rewards and optional Roblox badges.
- **Matchmaking.** Lobby queue for up to 6, teleported together into a reserved Chapter 1 server.
- **Saves.** DataStore with session locking, autosave every 2 minutes, save on leave and shutdown, self-healing schema.
- **First-time hints.** One-time tips (move, interact, light, fear, The Watcher, sprint, reviving) shown the first moment each matters, remembered per account.
- **Analytics.** Chapter 1 reports 10 funnel steps (boarded through chapter complete) to Roblox Analytics: as the onboarding funnel for first-time players and as a per-run "Chapter1" funnel, so the dashboard shows where players quit.
- **Accessibility.** Sound captions with direction, reduced flashing, reduced camera shake, calmer scares, colourblind markers, interface size, music and effects volume. Story text is always captioned.
