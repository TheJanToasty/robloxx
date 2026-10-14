--!strict
--[[
	Small helpers for building UI in code.

		local frame = Kit.new("Frame", { Size = UDim2.fromOffset(200, 80), Parent = screen }, {
			Kit.Corner(),
			Kit.Stroke(),
		})
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local SoundPlayer = require(script.Parent.Parent.Modules.SoundPlayer)
local Theme = require(script.Parent.Theme)

local Kit = {}

-- Creates an instance, sets its properties (Parent last) and parents the children to it.
function Kit.new(className: string, properties: { [string]: any }?, children: { any }?): any
	local instance = Instance.new(className)
	local parent = nil
	if properties then
		for key, value in properties do
			if key == "Parent" then
				parent = value
			else
				(instance :: any)[key] = value
			end
		end
	end
	if children then
		for _, child in children do
			child.Parent = instance
		end
	end
	instance.Parent = parent
	return instance
end

function Kit.Corner(radius: UDim?): any
	return Kit.new("UICorner", { CornerRadius = radius or Theme.Corner })
end

function Kit.Stroke(color: Color3?, thickness: number?, transparency: number?): any
	return Kit.new("UIStroke", {
		Color = color or Theme.Colors.Stroke,
		Thickness = thickness or 3,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

-- An outline around text (rather than around the frame).
function Kit.TextStroke(color: Color3?, thickness: number?): any
	return Kit.new("UIStroke", {
		Color = color or Theme.Colors.Stroke,
		Thickness = thickness or 2,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
	})
end

function Kit.Padding(top: number, right: number?, bottom: number?, left: number?): any
	return Kit.new("UIPadding", {
		PaddingTop = UDim.new(0, top),
		PaddingRight = UDim.new(0, right or top),
		PaddingBottom = UDim.new(0, bottom or top),
		PaddingLeft = UDim.new(0, left or right or top),
	})
end

function Kit.List(direction: Enum.FillDirection, padding: number, properties: { [string]: any }?): any
	local layout = Kit.new("UIListLayout", {
		FillDirection = direction,
		Padding = UDim.new(0, padding),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
	if properties then
		for key, value in properties do
			(layout :: any)[key] = value
		end
	end
	return layout
end

function Kit.Label(properties: { [string]: any }): any
	local label = Kit.new("TextLabel", {
		BackgroundTransparency = 1,
		Font = Theme.Font,
		TextColor3 = Theme.Colors.Text,
		TextSize = 20,
	})
	for key, value in properties do
		if key ~= "Parent" then
			(label :: any)[key] = value
		end
	end
	label.Parent = properties.Parent
	return label
end

-- A ScreenGui in the player's PlayerGui that scales with screen size.
function Kit.Screen(name: string, displayOrder: number?): ScreenGui
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local screen = Kit.new("ScreenGui", {
		Name = name,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = displayOrder or 0,
	})

	local scale = Kit.new("UIScale", { Parent = screen })
	local function update()
		local camera = Workspace.CurrentCamera
		if camera then
			local viewport = camera.ViewportSize
			scale.Scale = math.clamp(math.min(viewport.Y / Theme.DesignHeight, viewport.X / 1100), 0.5, 1.25)
		end
	end
	update()
	local camera = Workspace.CurrentCamera
	if camera then
		camera:GetPropertyChangedSignal("ViewportSize"):Connect(update)
	end

	screen.Parent = playerGui
	return screen
end

function Kit.Tween(
	instance: Instance,
	duration: number,
	goals: { [string]: any },
	style: Enum.EasingStyle?,
	direction: Enum.EasingDirection?
): Tween
	local tween = TweenService:Create(
		instance,
		TweenInfo.new(duration, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out),
		goals
	)
	tween:Play()
	return tween
end

-- A chunky rounded button that squishes when pressed. Calls onClick when activated.
function Kit.Button(properties: { [string]: any }, onClick: (() -> ())?): TextButton
	local color: Color3 = properties.BackgroundColor3 or Theme.Colors.Primary
	local button = Kit.new("TextButton", {
		AutoButtonColor = false,
		BackgroundColor3 = color,
		Font = Theme.Font,
		TextColor3 = Theme.Colors.TextLight,
		TextSize = 22,
		Size = UDim2.fromOffset(160, 48),
	}, {
		Kit.Corner(Theme.SmallCorner),
		Kit.Stroke(Theme.Colors.Stroke, 3),
		Kit.TextStroke(Theme.Colors.Stroke, 1.5),
	})
	for key, value in properties do
		if key ~= "Parent" then
			(button :: any)[key] = value
		end
	end

	local scale = Kit.new("UIScale", { Parent = button })
	button.MouseEnter:Connect(function()
		Kit.Tween(scale, 0.1, { Scale = 1.05 })
	end)
	button.MouseLeave:Connect(function()
		Kit.Tween(scale, 0.1, { Scale = 1 })
	end)
	button.MouseButton1Down:Connect(function()
		Kit.Tween(scale, 0.06, { Scale = 0.94 })
	end)
	button.MouseButton1Up:Connect(function()
		Kit.Tween(scale, 0.1, { Scale = 1 })
	end)
	if onClick then
		button.Activated:Connect(function()
			SoundPlayer.Play("Click")
			onClick()
		end)
	end

	button.Parent = properties.Parent
	return button
end

return Kit
