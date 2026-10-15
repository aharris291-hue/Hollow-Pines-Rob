-- Single registry of every remote. The server creates them on boot; the client
-- waits for them. Adding a remote means adding its name here and nowhere else.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Net = {}

local EVENTS = {
	-- server -> client
	"ProfileUpdated",
	"ObjectiveUpdated",
	"Caption",
	"Toast",
	"Cutscene",
	"ScreenEffect",
	"ChapterResult",
	"QueueUpdated",
	"DownedState",
	"PhotoEnding",
	"OpenPanel",
	"WalkiePing",
	-- client -> server
	"BuyItem",
	"EquipItem",
	"ChangeSetting",
	"ClaimQuest",
	"JoinQueue",
	"LeaveQueue",
	"ToggleLight",
	"UseTool",
	"SubmitRadioCode",
	"SetSprinting",
	"ReturnToLobby",
	"ReportLook",
}

local FUNCTIONS = {
	"GetProfile",
	"GetShopState",
}

local folder: Folder

local function getFolder(): Folder
	if folder then
		return folder
	end
	if RunService:IsServer() then
		folder = ReplicatedStorage:FindFirstChild("Remotes") :: Folder
		if not folder then
			folder = Instance.new("Folder")
			folder.Name = "Remotes"
			folder.Parent = ReplicatedStorage
		end
		for _, name in EVENTS do
			if not folder:FindFirstChild(name) then
				local remote = Instance.new("RemoteEvent")
				remote.Name = name
				remote.Parent = folder
			end
		end
		for _, name in FUNCTIONS do
			if not folder:FindFirstChild(name) then
				local remote = Instance.new("RemoteFunction")
				remote.Name = name
				remote.Parent = folder
			end
		end
	else
		folder = ReplicatedStorage:WaitForChild("Remotes") :: Folder
	end
	return folder
end

function Net.Event(name: string): RemoteEvent
	assert(table.find(EVENTS, name), "Unknown remote event " .. name)
	return getFolder():WaitForChild(name) :: RemoteEvent
end

function Net.Function(name: string): RemoteFunction
	assert(table.find(FUNCTIONS, name), "Unknown remote function " .. name)
	return getFolder():WaitForChild(name) :: RemoteFunction
end

function Net.Setup()
	getFolder()
end

return Net
