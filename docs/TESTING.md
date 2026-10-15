# Testing

## Automated

```sh
lune run tests/run
```

- Compiles every `.luau` file in `src/` (catches syntax errors).
- Unit specs in `tests/specs/` for the pure modules: fear maths, XP curve, daily quest selection and progress, save reconciliation, radio puzzle codes, rate limiting and signals.

Code that touches Roblox services is checked in Studio with the list below.

## Manual playtest checklist

Run in Studio with *Clients and Servers*, once solo and once with 3 players.

**Flow**
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

**Systems**
- [ ] On a fresh save, tips appear once each (move, interact, light, fear, The Watcher, sprint, revive) and not again after rejoining
- [ ] Fear rises alone in the dark and falls with light, teammates and in the station
- [ ] Sprint drains stamina; Panicked slows you
- [ ] Shop buys deduct Embers; equip/unequip beams, titles, pets
- [ ] Quests progress and can be claimed once
- [ ] Settings save and apply (captions, flashing, shake, calmer scares, markers, size, volume)
- [ ] Leave and rejoin: Embers, level, items and settings persist
- [ ] Lobby: Play queues, countdown runs, group teleports together (published game only)

**Devices**
- [ ] Mobile: Run and Light buttons, menus fit on a phone screen
- [ ] Gamepad: L3 sprint, Y light

## Performance targets

- Chapter 1 greybox: about 3,000 parts (650 trees). Keep server heartbeat above 55 Hz with 6 players.
- Creature AI ticks at 10 Hz; fear at 4 Hz; equipment at 2 Hz.
- Profile replication is batched to one message per player per frame.
