-- Sprint (Shift / mobile button), light toggle (F / mobile button) and the
-- camera direction report The Watcher uses to know who is looking at it.

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared.Util.Net)

local InputController = {}

local LOOK_INTERVAL = 0.15

local function isChapter(): boolean
	return ReplicatedStorage:GetAttribute("PlaceRole") ~= "Lobby"
end

function InputController:Start()
	if not isChapter() then
		return
	end

	ContextActionService:BindAction("Sprint", function(_, inputState)
		if inputState == Enum.UserInputState.Begin then
			Net.Event("SetSprinting"):FireServer(true)
		elseif inputState == Enum.UserInputState.End or inputState == Enum.UserInputState.Cancel then
			Net.Event("SetSprinting"):FireServer(false)
		end
		return Enum.ContextActionResult.Pass
	end, true, Enum.KeyCode.LeftShift, Enum.KeyCode.ButtonL3)
	ContextActionService:SetTitle("Sprint", "Run")
	ContextActionService:SetPosition("Sprint", UDim2.new(1, -170, 1, -150))

	ContextActionService:BindAction("ToggleLight", function(_, inputState)
		if inputState == Enum.UserInputState.Begin then
			Net.Event("ToggleLight"):FireServer()
		end
		return Enum.ContextActionResult.Pass
	end, true, Enum.KeyCode.F, Enum.KeyCode.ButtonY)
	ContextActionService:SetTitle("ToggleLight", "Light")
	ContextActionService:SetPosition("ToggleLight", UDim2.new(1, -170, 1, -90))

	local camera = workspace.CurrentCamera
	local lastSent = Vector3.zero
	while true do
		task.wait(LOOK_INTERVAL)
		camera = workspace.CurrentCamera
		if camera and Players.LocalPlayer.Character then
			local look = camera.CFrame.LookVector
			if (look - lastSent).Magnitude > 0.03 then
				lastSent = look
				Net.Event("ReportLook"):FireServer(look)
			end
		end
	end
end

return InputController
