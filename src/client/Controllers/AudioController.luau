-- Plays 2D sounds by asset id and applies the volume settings.
-- An id of 0 means the sound has not been chosen yet (Config/Assets) and is skipped.

local SoundService = game:GetService("SoundService")

local AudioController = {}

local controllers
local loops: { [string]: Sound } = {}

local function group(name: string): SoundGroup?
	return SoundService:FindFirstChild(name) :: SoundGroup?
end

function AudioController:Init(registry)
	controllers = registry
end

function AudioController:Start()
	controllers.DataController:Observe(function(profile)
		local music, effects = group("Music"), group("Effects")
		if music then
			music.Volume = profile.Settings.MusicVolume
		end
		if effects then
			effects.Volume = profile.Settings.EffectsVolume
		end
	end)
end

function AudioController:Play(soundId: number?, volume: number?, groupName: string?)
	if not soundId or soundId == 0 then
		return nil
	end
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://" .. soundId
	sound.Volume = volume or 0.8
	sound.SoundGroup = group(groupName or "Effects")
	sound.Parent = SoundService
	sound.Ended:Once(function()
		sound:Destroy()
	end)
	sound:Play()
	return sound
end

function AudioController:Loop(key: string, soundId: number?, volume: number?, groupName: string?)
	self:StopLoop(key)
	if not soundId or soundId == 0 then
		return
	end
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://" .. soundId
	sound.Volume = volume or 0.6
	sound.Looped = true
	sound.SoundGroup = group(groupName or "Music")
	sound.Parent = SoundService
	sound:Play()
	loops[key] = sound
end

function AudioController:StopLoop(key: string)
	if loops[key] then
		loops[key]:Destroy()
		loops[key] = nil
	end
end

function AudioController:GetLoop(key: string): Sound?
	return loops[key]
end

return AudioController
