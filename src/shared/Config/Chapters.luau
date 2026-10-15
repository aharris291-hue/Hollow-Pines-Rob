-- The chapter list, shared so the lobby can show it and the server can run it.
-- `requires` is the chapter that must be cleared first; `place` is the key in
-- GameConfig.Places for that chapter's published place.

return {
	{ id = 1, name = "The Storm", blurb = "A bus crash, a missing driver, and something in the trees.", place = "Chapter1" },
	{ id = 2, name = "The Ranger", blurb = "A flooded campground. Something with a lantern hears everything.", place = "Chapter2", requires = 1 },
	{ id = 3, name = "Voices", blurb = "A village in the fog. One of your friends isn't your friend.", place = "Chapter3", requires = 2 },
}
