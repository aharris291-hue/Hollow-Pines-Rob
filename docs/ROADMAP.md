# Roadmap

## Phase 1: Chapter 1 MVP (this repository)

Core systems, Chapter 1 greybox, lobby, monetization, saves, accessibility, tests.

## Phase 2: Polish and soft launch

- Replace greybox with art: modelled bus, station interior, terrain forest, The Watcher model and animations.
- Audio pass (fill `Assets.luau`), ambience zones, voice lines for the radio and The Mimic.
- Tutorial hints for first-time players; FTUE analytics funnel.
- Party invites (friends join the same queue) via `SocialService`.
- Soft launch, watch retention and chase difficulty.

## Phase 3: Chapter 2, "The Ranger" (built, greybox)

- Done: The Ranger patrols with a lantern and hunts by sound (sprinting, splashing, walkie and whistle are loud). He can't reach players still in a tent, in the lit office or up the tower.
- Done: the flooded campground, boathouse and lookout tower; whistle story item; torn map pieces; lobby chapter select.
- Next: art pass for the camp and The Ranger, Ranger voice lines and footsteps, tuning hearing ranges from playtests.

## Phase 4: Chapter 3, "Voices" (built, greybox)

- Done: The Mimic walks as a copy of a player, fakes walkie pings and catches only players who are alone.
- Done: the secret handshake to prove you are real; Millbrook village, Hale's tapes, the three signals and the ferry finale.
- Next: voice lines, a fog art pass.

## Phase 5: Chapter 4, "The Hollow" (built, greybox)

- Done: The Hollow One's sweeping gaze and stone cover, waking the lost, the stone fires, the last chase and the ending.
- Next: art pass for the Hollow and the groves.

## Polish 1 (built)

- Done: hand-made creature animation with no uploaded assets. The server builds the Watcher and the Ranger with joints, and each player's screen swings their limbs (`Util/Gait`, `CreatureAnimator`). The copy walks with dead-still arms. The Hollow One's branches sway.
- Done: credits roll after the final photo (edit `Config/Credits.luau`), skippable.
- Done: an Invite friends button in the lobby.

## After the story

- Phase 2's polish list now covers all four chapters: art and audio (`Assets.luau`). Real uploaded animations can replace the hand-made ones later.
- Publish all five places (docs/DEPLOYMENT.md) and soft launch.

## Live service

- Seasonal events (Halloween storm, winter lights) with limited cosmetics earnable by play.
- Weekly quest rotations, leaderboards for fastest clears.
- New pets and beam colours each update.
