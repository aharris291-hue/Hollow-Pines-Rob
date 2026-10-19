-- Tiny declarative helpers for building UI in code, plus the shared theme.

local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Assets = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared").Config.Assets)

local UIKit = {}

UIKit.Theme = {
	Panel = Color3.fromRGB(16, 18, 24),
	PanelLight = Color3.fromRGB(30, 33, 42),
	Stroke = Color3.fromRGB(70, 74, 90),
	Text = Color3.fromRGB(236, 232, 222),
	Muted = Color3.fromRGB(160, 160, 170),
	Accent = Color3.fromRGB(255, 186, 102),
	Danger = Color3.fromRGB(235, 92, 82),
	Success = Color3.fromRGB(120, 210, 140),
	Calm = Color3.fromRGB(110, 190, 255),
	Font = Enum.Font.GothamMedium,
	FontBold = Enum.Font.GothamBold,
	Story = Enum.Font.Merriweather,
}

-- UIKit.new("Frame", { Size = ..., Parent = ... }, { children })
function UIKit.new(className: string, props, children)
	local instance = Instance.new(className)
	local parent = nil
	for key, value in props or {} do
		if key == "Parent" then
			parent = value
		else
			instance[key] = value
		end
	end
	for _, child in children or {} do
		child.Parent = instance
	end
	instance.Parent = parent
	return instance
end

function UIKit.corner(radius: number?)
	return UIKit.new("UICorner", { CornerRadius = UDim.new(0, radius or 10) })
end

function UIKit.stroke(color: Color3?, thickness: number?)
	return UIKit.new("UIStroke", { Color = color or UIKit.Theme.Stroke, Thickness = thickness or 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
end

function UIKit.padding(pixels: number)
	local p = UDim.new(0, pixels)
	return UIKit.new("UIPadding", { PaddingTop = p, PaddingBottom = p, PaddingLeft = p, PaddingRight = p })
end

function UIKit.list(direction: Enum.FillDirection?, gap: number?, align: Enum.HorizontalAlignment?)
	return UIKit.new("UIListLayout", {
		FillDirection = direction or Enum.FillDirection.Vertical,
		Padding = UDim.new(0, gap or 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = align or Enum.HorizontalAlignment.Left,
	})
end

function UIKit.panel(props)
	local frame = UIKit.new("Frame", {
		BackgroundColor3 = UIKit.Theme.Panel,
		BackgroundTransparency = 0.15,
		BorderSizePixel = 0,
	}, { UIKit.corner(), UIKit.stroke() })
	for key, value in props do
		if key == "Parent" then
			continue
		end
		frame[key] = value
	end
	frame.Parent = props.Parent
	return frame
end

function UIKit.text(props)
	local label = UIKit.new("TextLabel", {
		BackgroundTransparency = 1,
		Font = UIKit.Theme.Font,
		TextColor3 = UIKit.Theme.Text,
		TextSize = 16,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, 20),
	})
	for key, value in props do
		if key == "Parent" then
			continue
		end
		label[key] = value
	end
	label.Parent = props.Parent
	return label
end

-- A soft click for buttons (Config/Assets UIClick; 0 means silent).
local clickSound: Sound? = nil
function UIKit.click()
	if Assets.Sounds.UIClick == 0 then
		return
	end
	if not clickSound then
		local sound = Instance.new("Sound")
		sound.SoundId = "rbxassetid://" .. Assets.Sounds.UIClick
		sound.Volume = 0.4
		sound.SoundGroup = SoundService:FindFirstChild("Effects") :: SoundGroup?
		sound.Parent = SoundService
		clickSound = sound
	end
	(clickSound :: Sound):Play()
end

function UIKit.button(text: string, props, onClick: () -> ())
	local button = UIKit.new("TextButton", {
		Text = text,
		AutoButtonColor = false,
		BackgroundColor3 = UIKit.Theme.PanelLight,
		BorderSizePixel = 0,
		Font = UIKit.Theme.FontBold,
		TextColor3 = UIKit.Theme.Text,
		TextSize = 16,
		Size = UDim2.fromOffset(140, 38),
	}, { UIKit.corner(8), UIKit.stroke() })
	for key, value in props or {} do
		if key == "Parent" then
			continue
		end
		button[key] = value
	end
	local base = button.BackgroundColor3
	button.MouseEnter:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.12), { BackgroundColor3 = base:Lerp(Color3.new(1, 1, 1), 0.12) }):Play()
	end)
	button.MouseLeave:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.12), { BackgroundColor3 = base }):Play()
	end)
	button.Activated:Connect(function()
		UIKit.click()
		onClick()
	end)
	button.Parent = props and props.Parent
	return button
end

function UIKit.bar(props)
	local back = UIKit.new("Frame", {
		BackgroundColor3 = Color3.fromRGB(10, 10, 14),
		BackgroundTransparency = 0.3,
		BorderSizePixel = 0,
		Size = props.Size,
		Position = props.Position or UDim2.new(),
		LayoutOrder = props.LayoutOrder or 0,
		Parent = props.Parent,
	}, { UIKit.corner(6) })
	local fill = UIKit.new("Frame", {
		Name = "Fill",
		BackgroundColor3 = props.Color,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(0, 1),
		Parent = back,
	}, { UIKit.corner(6) })
	local label = UIKit.text({
		Name = "Label",
		Size = UDim2.fromScale(1, 1),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextSize = 13,
		Font = UIKit.Theme.FontBold,
		ZIndex = 2,
		Text = props.Text or "",
		Parent = back,
	})
	return back, fill, label
end

function UIKit.tween(instance: Instance, seconds: number, goal)
	local tween = TweenService:Create(instance, TweenInfo.new(seconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), goal)
	tween:Play()
	return tween
end

function UIKit.clear(container: Instance)
	for _, child in container:GetChildren() do
		if not child:IsA("UIListLayout") and not child:IsA("UIGridLayout") and not child:IsA("UIPadding") then
			child:Destroy()
		end
	end
end

return UIKit
