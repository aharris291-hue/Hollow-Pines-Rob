-- Which chapters a profile has cleared and may start. Pure, so the lobby UI and
-- the matchmaking server agree (and it can be unit tested).

local ChapterUnlock = {}

function ChapterUnlock.isCleared(profile, chapterId: number): boolean
	if not profile then
		return false
	end
	if profile.Cleared and profile.Cleared[tostring(chapterId)] then
		return true
	end
	-- Saves from before `Cleared` existed only remember Chapter 1.
	return chapterId == 1 and profile.FirstClear == true
end

-- `chapter` is an entry from Config/Chapters.
function ChapterUnlock.isUnlocked(profile, chapter): boolean
	if not chapter then
		return false
	end
	return chapter.requires == nil or ChapterUnlock.isCleared(profile, chapter.requires)
end

function ChapterUnlock.find(chapters, chapterId: any)
	for _, chapter in chapters do
		if chapter.id == chapterId then
			return chapter
		end
	end
	return nil
end

return ChapterUnlock
