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

## Chapter 2: The Ranger (about 15–20 minutes)

Unlocked by escaping Chapter 1. Chapter 1 teaches looking; Chapter 2 teaches listening.

1. **Intro.** The rescue truck stops at the gate of the Hollow Pines Campground. The driver is gone.
2. **The camp.** Flooded paths and rows of tents. Running and splashing through water make noise (a HUD line shows how loud you are).
3. **Camp office.** The rescue crew on the walkie: Ranger Hale "isn't himself", he hears everything, and there's a flare gun in the boathouse. The office is lit and safe. Then a lantern appears between the tents: The Ranger starts patrolling.
4. **Whistles.** The lost and found box gives everyone a camp whistle. Blowing it is very loud, so it pulls The Ranger to whoever blew it, away from friends.
5. **Torn map pieces.** Ranger Hale's log explains he tore the boathouse lock code into four map pieces. Four of ten hiding places are used each run, and the digits change per server.
6. **Boathouse.** The four numbers open the padlock; the flare gun is inside.
7. **Lookout tower.** Climb the ladder and fire the flare. The whole camp hears it, and The Ranger stands guard at the bottom of the ladder. He can't climb, so the team holds out on the platform.
8. **Helicopter.** The searchlight drives him back for a moment. Everyone runs to the landing pad while he hunts the nearest player he can reach.
9. **The photograph.** Taken from the air: Ranger Hale at the foot of the tower, lantern raised, looking up at the tall shape standing on the tower roof.

## Creatures

| Creature | Story role | Behaviour |
| --- | --- | --- |
| The Watcher | Antagonist | Stalks from the tree line, repositions where nobody is looking, vanishes after eye contact, raises fear nearby. Hunts in the finale. A camera flash makes it look away. |
| The Mimic | Teaser | Voice lines using players' names; a decoy wearing a teammate's avatar. Harmless in Chapter 1. |
| The Ranger | Voice on the radio (Ch. 1), hunter (Ch. 2) | Patrols the camp with a lantern. Investigates noises (sprinting, splashing, walkies, whistles), sees farther if your light is on, chases what he sees. Can't reach players who stand still in a tent, are in the lit office, or are up the tower. A camera flash stuns him. |
| The Hollow One | Unseen | The secret at the centre of the forest, Chapter 4. |

## Systems

- **Fear (0–100).** Rises in darkness, alone, and near The Watcher; falls with a light, near teammates, near a teammate's lantern, and inside the powered station. Tiers: Calm, Uneasy (35), Scared (65), Panicked (90). Panicked slows walking. Effects: vignette, desaturation, heartbeat, light shake. Tuning in `src/shared/Config/GameConfig.luau`.
- **Movement.** Walk 12, sprint 20 with stamina.
- **Downed and revive.** Caught players drop to the ground; a teammate holds the prompt for 3 s to help them up, otherwise they wake at the checkpoint after 25 s.
- **Noise and hiding (Chapter 2).** Sprinting, splashing, walkie pings, whistles and the flare make noises with a radius; The Ranger goes to the loudest one he hears. Standing still in a tent hides you.
- **Equipment.** Two slots (Light, Tool), plus story items handed out in a chapter (the whistle). Flashlight (Lv1), Walkie ping (Lv2), Calming flask (Lv3), Storm lantern (Lv4), Instant camera (Lv6). Unlocked by level, never sold.
- **Progression.** XP from the chapter and quests, curve `100 × level^1.4`, max level 50, Embers on every level and more every fifth.
- **Economy.** One currency, Embers: earned from play, quests, achievements and levels; spent on beam colours, titles and pets.
- **Pets.** Cosmetic companions that float beside you.
- **Quests.** Three daily quests per UTC day, same on every server.
- **Achievements.** Twelve, from lifetime stats, some with title rewards and optional Roblox badges.
- **Matchmaking.** The lobby shows a chapter picker; each chapter has its own queue for up to 6, teleported together into a reserved server of that chapter. Locked chapters are refused by the server too.
- **Saves.** DataStore with session locking, autosave every 2 minutes, save on leave and shutdown, self-healing schema.
- **First-time hints.** One-time tips (move, interact, light, fear, The Watcher, sprint, reviving, noise, hiding, the whistle) shown the first moment each matters, remembered per account.
- **Analytics.** Each chapter reports funnel steps to Roblox Analytics as a per-run "Chapter1" / "Chapter2" funnel, so the dashboard shows where players quit. Chapter 1's steps also feed the onboarding funnel for first-time players.
- **Accessibility.** Sound captions with direction, reduced flashing, reduced camera shake, calmer scares, colourblind markers, interface size, music and effects volume. Story text is always captioned.
