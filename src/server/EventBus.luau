-- Server-wide gameplay events. Gameplay code fires facts ("FuseInserted"); quests,
-- achievements and analytics listen, so systems never call each other directly.
--
-- EventBus.Fire(name, player, amount?)
-- EventBus.Event:Connect(function(name, player, amount) end)

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Signal = require(Shared.Util.Signal)

local EventBus = {}

EventBus.Event = Signal.new()

function EventBus.Fire(name: string, player: Player?, amount: number?)
	EventBus.Event:Fire(name, player, amount or 1)
end

return EventBus
