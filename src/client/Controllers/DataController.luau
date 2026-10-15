-- Local copy of the player's profile, kept current by the server.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Net = require(Shared.Util.Net)
local Signal = require(Shared.Util.Signal)

local DataController = {}

DataController.Changed = Signal.new() -- (profile)
DataController.Profile = nil

function DataController:Init()
	Net.Event("ProfileUpdated").OnClientEvent:Connect(function(profile)
		self.Profile = profile
		self.Changed:Fire(profile)
	end)
end

function DataController:Start()
	if not self.Profile then
		local ok, profile = pcall(function()
			return Net.Function("GetProfile"):InvokeServer()
		end)
		if ok and profile and not self.Profile then
			self.Profile = profile
			self.Changed:Fire(profile)
		end
	end
end

function DataController:Setting(key: string)
	return self.Profile and self.Profile.Settings[key]
end

-- Call fn now (if loaded) and on every change.
function DataController:Observe(fn)
	if self.Profile then
		task.spawn(fn, self.Profile)
	end
	return self.Changed:Connect(fn)
end

return DataController
