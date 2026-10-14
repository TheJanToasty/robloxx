--!strict
--[[
	A pop-up window with a coloured title bar and a close button. Only one window
	is open at a time; opening another closes the current one.

	Works with mouse, touch and gamepad (B closes it, and the first button is
	selected automatically when using a controller).
]]

local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")

local Kit = require(script.Parent.Kit)
local Theme = require(script.Parent.Theme)

export type Window = {
	Frame: Frame,
	Content: Frame,
	Title: TextLabel,
	IsOpen: boolean,
	Open: (self: Window) -> (),
	Close: (self: Window) -> (),
	Toggle: (self: Window) -> (),
	-- Called after the window opens/closes.
	OnOpened: (() -> ())?,
	OnClosed: (() -> ())?,
}

local Window = {}
Window.__index = Window

local current: Window? = nil
local CLOSE_ACTION = "CloseWindow"

local function usingGamepad(): boolean
	return UserInputService:GetLastInputType().Name:find("Gamepad") ~= nil
end

function Window.new(parent: Instance, title: string, size: Vector2, color: Color3?): Window
	local scale = Kit.new("UIScale", { Scale = 0 })
	local frame = Kit.new("Frame", {
		Name = title .. "Window",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(size.X, size.Y),
		BackgroundColor3 = Theme.Colors.Panel,
		Visible = false,
		Parent = parent,
	}, { scale, Kit.Corner(UDim.new(0, 20)), Kit.Stroke(Theme.Colors.Stroke, 4) })

	local header = Kit.new("Frame", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, 58),
		BackgroundColor3 = color or Theme.Colors.Primary,
		Parent = frame,
	}, { Kit.Corner(UDim.new(0, 20)) })
	-- Square off the bottom corners of the header.
	Kit.new("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, 20),
		BackgroundColor3 = color or Theme.Colors.Primary,
		BorderSizePixel = 0,
		Parent = header,
	})
	local titleLabel = Kit.new("TextLabel", {
		Name = "Title",
		Position = UDim2.fromOffset(20, 0),
		Size = UDim2.new(1, -80, 1, 0),
		BackgroundTransparency = 1,
		Font = Theme.Font,
		Text = title,
		TextSize = 30,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Theme.Colors.TextLight,
		ZIndex = 2,
		Parent = header,
	}, { Kit.TextStroke(Theme.Colors.Stroke, 2.5) })

	local content = Kit.new("Frame", {
		Name = "Content",
		Position = UDim2.fromOffset(0, 58),
		Size = UDim2.new(1, 0, 1, -58),
		BackgroundTransparency = 1,
		Parent = frame,
	}, { Kit.Padding(14) })

	local self = setmetatable({
		Frame = frame,
		Content = content,
		Title = titleLabel,
		IsOpen = false,
		_scale = scale,
	}, Window) :: any

	Kit.Button({
		Name = "Close",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(1, -8, 0, 8),
		Size = UDim2.fromOffset(46, 46),
		BackgroundColor3 = Theme.Colors.Danger,
		Text = "X",
		TextSize = 26,
		ZIndex = 3,
		Parent = frame,
	}, function()
		self:Close()
	end)

	return self
end

function Window.Open(self: any)
	if self.IsOpen then
		return
	end
	if current and current ~= self then
		current:Close()
	end
	current = self
	self.IsOpen = true
	self.Frame.Visible = true
	self._scale.Scale = 0.6
	Kit.Tween(self._scale, 0.25, { Scale = 1 }, Enum.EasingStyle.Back)

	ContextActionService:BindAction(CLOSE_ACTION, function(_, inputState)
		if inputState == Enum.UserInputState.Begin then
			self:Close()
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.KeyCode.ButtonB)

	if self.OnOpened then
		self.OnOpened()
	end

	if usingGamepad() then
		for _, descendant in self.Content:GetDescendants() do
			if descendant:IsA("GuiButton") and descendant.Visible then
				GuiService.SelectedObject = descendant
				break
			end
		end
	end
end

function Window.Close(self: any)
	if not self.IsOpen then
		return
	end
	self.IsOpen = false
	if current == self then
		current = nil
		ContextActionService:UnbindAction(CLOSE_ACTION)
	end
	if GuiService.SelectedObject and GuiService.SelectedObject:IsDescendantOf(self.Frame) then
		GuiService.SelectedObject = nil
	end
	local tween = Kit.Tween(self._scale, 0.15, { Scale = 0 }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
	tween.Completed:Once(function()
		if not self.IsOpen then
			self.Frame.Visible = false
		end
	end)
	if self.OnClosed then
		self.OnClosed()
	end
end

function Window.Toggle(self: any)
	if self.IsOpen then
		self:Close()
	else
		self:Open()
	end
end

return Window
