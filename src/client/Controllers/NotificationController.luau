--!strict
--[[
	Pop-up messages at the top of the screen. The server sends them through the
	Notify remote; client code can call NotificationController:Show directly.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage:WaitForChild("Shared").Modules.Remotes)
local SoundPlayer = require(script.Parent.Parent.Modules.SoundPlayer)
local Kit = require(script.Parent.Parent.UI.Kit)
local Theme = require(script.Parent.Parent.UI.Theme)

local MAX_VISIBLE = 4
local DURATION = 3

local KIND_COLORS = {
	Info = Theme.Colors.Primary,
	Success = Theme.Colors.Success,
	Error = Theme.Colors.Danger,
	Rare = Color3.fromRGB(255, 72, 146),
}

local NotificationController = {}

local container: Frame
local order = 0

local function dismiss(toast: Frame)
	if toast:GetAttribute("Closing") then
		return
	end
	toast:SetAttribute("Closing", true)
	local scale = toast:FindFirstChildOfClass("UIScale")
	if scale then
		Kit.Tween(scale, 0.18, { Scale = 0 }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
	end
	task.delay(0.2, function()
		toast:Destroy()
	end)
end

function NotificationController:Show(message: string, kind: string?)
	local color = KIND_COLORS[kind or "Info"] or Theme.Colors.Primary

	-- Drop the oldest if too many are showing.
	local toasts = {}
	for _, child in container:GetChildren() do
		if child:IsA("Frame") and not child:GetAttribute("Closing") then
			table.insert(toasts, child)
		end
	end
	table.sort(toasts, function(a, b)
		return a.LayoutOrder < b.LayoutOrder
	end)
	if #toasts >= MAX_VISIBLE then
		dismiss(toasts[1])
	end

	order += 1
	local scale = Kit.new("UIScale", { Scale = 0 })
	local toast = Kit.new("Frame", {
		Name = "Toast",
		LayoutOrder = order,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 46),
		BackgroundColor3 = color,
		Parent = container,
	}, {
		scale,
		Kit.Corner(UDim.new(0, 12)),
		Kit.Stroke(Theme.Colors.Stroke, 3),
		Kit.Padding(0, 18, 0, 18),
		Kit.new("TextLabel", {
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.fromScale(0, 1),
			BackgroundTransparency = 1,
			Font = Theme.Font,
			Text = message,
			TextSize = 22,
			TextColor3 = Theme.Colors.TextLight,
		}, { Kit.TextStroke(Theme.Colors.Stroke, 1.5) }),
	})

	Kit.Tween(scale, 0.25, { Scale = 1 }, Enum.EasingStyle.Back)
	if kind == "Error" then
		SoundPlayer.Play("Error")
	end
	task.delay(if kind == "Rare" then DURATION + 2 else DURATION, dismiss, toast)
end

function NotificationController:Init()
	local screen = Kit.Screen("Notifications", 20)
	container = Kit.new("Frame", {
		Name = "Container",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 12),
		Size = UDim2.new(0.9, 0, 0, 300),
		BackgroundTransparency = 1,
		Parent = screen,
	}, {
		Kit.List(Enum.FillDirection.Vertical, 8, {
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
		}),
	})
end

function NotificationController:Start()
	Remotes.Event("Notify").OnClientEvent:Connect(function(message: string, kind: string)
		self:Show(message, kind)
	end)
end

return NotificationController
