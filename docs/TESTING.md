# Testing

## Automated

```sh
lune run tests/run
```

- Compiles every `.luau` file in `src/` (catches syntax errors).
- Unit specs in `tests/specs/` for the pure modules: fear maths, XP curve, daily quest selection and progress, save reconciliation, radio puzzle codes, rate limiting, signals, The Ranger's hearing and chapter unlocks.

Code that touches Roblox services is checked in Studio with the list below.

## Manual playtest checklist

Run in Studio with *Clients and Servers*, once solo and once with 3 players.
`default.project.json` plays Chapter 1; `solo-chapter2.project.json` plays Chapter 2.

**Chapter 1 flow**
- [ ] Intro plays, then everyone wakes in the bus
- [ ] Driver's seat note opens; objective advances
- [ ] Emergency kit gives every player their loadout; F toggles the light
- [ ] Midway along the trail The Watcher appears; looking at it makes it vanish
- [ ] Three fuses spawn; inserting them shows 1/3, 2/3, 3/3; lights come on
- [ ] Clue notes show three digits; the radio accepts the right code and rejects wrong ones
- [ ] Radio dialogue plays, a voice uses a player's name, a decoy appears and vanishes when approached
- [ ] Map table sets the bridge objective
- [ ] Leaving the station starts the chase; being caught downs you; a teammate can revive
- [ ] Bleeding out wakes you at the checkpoint
- [ ] Reaching Route 9 marks you safe; the photograph ending and results show
- [ ] Rewards arrive (Embers, XP, achievements)

**Chapter 2 flow**
- [ ] Intro shows "Chapter 2 / The Ranger"; everyone starts by the empty rescue truck with their loadout
- [ ] Entering the camp shows the noise tip; the HUD noise line reads quiet / some / LOUD when walking, sprinting, splashing
- [ ] At the office the walkie lines play, then The Ranger appears and patrols; he does not enter the lit office
- [ ] Sprinting or splashing near him makes him walk to the sound; standing still in a tent shows "Hidden" and he loses you
- [ ] Lost and found gives everyone a whistle (slot 3); blowing it pulls him to the whistler
- [ ] Four map pieces spawn; each shows one number; the padlock accepts the 4-digit code and rejects wrong ones
- [ ] Flare gun in the boathouse; ladder can be climbed; firing the flare tints the sky red and he guards the ladder
- [ ] After about 45 s the landing light comes on, he backs off, then hunts; reaching the pad marks you safe
- [ ] The tower photograph ending and results ("Chapter 2 complete") show

**Systems**
- [ ] On a fresh save, tips appear once each (move, interact, light, fear, The Watcher, sprint, revive) and not again after rejoining
- [ ] Fear rises alone in the dark and falls with light, teammates and in the station
- [ ] Sprint drains stamina; Panicked slows you
- [ ] Shop buys deduct Embers; equip/unequip beams, titles, pets
- [ ] Quests progress and can be claimed once
- [ ] Settings save and apply (captions, flashing, shake, calmer scares, markers, size, volume)
- [ ] Leave and rejoin: Embers, level, items and settings persist
- [ ] Lobby: Chapter 2 shows locked on a fresh save and unlocked after a Chapter 1 clear; Play queues the picked chapter, countdown runs, group teleports together (published game only)

**Devices**
- [ ] Mobile: Run and Light buttons, menus fit on a phone screen
- [ ] Gamepad: L3 sprint, Y light

## Performance targets

- Chapter 1 greybox: about 3,500 parts (650 trees). Chapter 2: about 2,300 parts. Keep server heartbeat above 55 Hz with 6 players.
- Creature AI ticks at 10 Hz; fear at 4 Hz; equipment at 2 Hz.
- Profile replication is batched to one message per player per frame.
