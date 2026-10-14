--!strict
--[[
	The player's side of fishing: turns rod clicks/taps/R2 into Cast and Reel
	requests, shows the bite alert and catch card, and keeps a hint on screen so
	new players know what to do next.

	The server decides everything; this only asks and displays.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local FishingConfig = require(Shared.Config.Fishing)
local MapConfig = require(Shared.Config.Map)
local Remotes = require(Shared.Modules.Remotes)
local SoundPlayer = require(script.Parent.Parent.Modules.SoundPlayer)
local CatchCard = require(script.Parent.Parent.UI.CatchCard)
local Kit = require(script.Parent.Parent.UI.Kit)
local Theme = require(script.Parent.Parent.UI.Theme)
local DataController = require(script.Parent.DataController)
local NotificationController = require(script.Parent.NotificationController)

local player = Players.LocalPlayer

type State = "Idle" | "Requesting" | "Fishing" | "Biting"

local FishingController = {}

local state: State = "Idle"
-- Goes up whenever a fishing attempt ends, so a slow Cast reply can't undo it.
local attempt = 0
local currentTool: Tool? = nil
local toolConnection: RBXScriptConnection? = nil

local hintLabel: TextLabel
local bitePrompt: Frame
local biteScale: UIScale
local biteBar: Frame

local CANCEL_MESSAGES = {
	Early = "Too early! Wait for the bobber to dip.",
	TooFar = "You walked too far, so you reeled in.",
}

local function inputWord(): string
	local lastInput = UserInputService:GetLastInputType()
	if lastInput == Enum.UserInputType.Touch then
		return "Tap"
	elseif lastInput.Name:find("Gamepad") then
		return "Press R2"
	end
	return "Click"
end

local function isNearPond(): boolean
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return false
	end
	local position = root.Position
	local distance = Vector3.new(position.X, 0, position.Z).Magnitude
	return distance <= MapConfig.PondRadius + FishingConfig.MaxShoreDistance
end

local function updateHint()
	local text = ""
	if not DataController.IsLoaded then
		text = ""
	elseif not currentTool then
		local word = inputWord()
		text = if word == "Click" then "Press 1 to equip your fishing rod" else "Equip your fishing rod from the hotbar"
	elseif state == "Idle" then
		text = if isNearPond() then `{inputWord()} to cast!` else "Walk to the pond to fish!"
	elseif state == "Fishing" or state == "Requesting" then
		text = "Waiting for a bite..."
	end
	hintLabel.Text = text
	hintLabel.Visible = text ~= ""
end

local function hideBite()
	bitePrompt.Visible = false
end

local function showBite(window: number)
	bitePrompt.Visible = true
	biteScale.Scale = 0.4
	Kit.Tween(biteScale, 0.2, { Scale = 1 }, Enum.EasingStyle.Back)
	biteBar.Size = UDim2.fromScale(1, 1)
	Kit.Tween(biteBar, window, { Size = UDim2.fromScale(0, 1) }, Enum.EasingStyle.Linear)
	local label = bitePrompt:FindFirstChild("Action") :: TextLabel?
	if label then
		label.Text = `{string.upper(inputWord())} NOW!`
	end
end

local function finish()
	attempt += 1
	state = "Idle"
	hideBite()
	updateHint()
end

local function onActivated()
	if state == "Requesting" then
		return
	end

	local myAttempt = attempt
	if state == "Idle" then
		state = "Requesting"
		updateHint()
		local ok, message = Remotes.Function("FishingAction"):InvokeServer("Cast")
		if attempt ~= myAttempt then
			return
		end
		if ok then
			state = "Fishing"
		else
			state = "Idle"
			if message then
				NotificationController:Show(message, "Error")
			end
		end
		updateHint()
	else
		-- Fishing or Biting: reel in. The result arrives as a FishingEvent.
		state = "Requesting"
		hideBite()
		Remotes.Function("FishingAction"):InvokeServer("Reel")
		if attempt == myAttempt then
			finish()
		end
	end
end

local function setTool(tool: Tool?)
	if toolConnection then
		toolConnection:Disconnect()
		toolConnection = nil
	end
	currentTool = tool
	if tool then
		toolConnection = tool.Activated:Connect(onActivated)
	end
	-- Unequipping cancels fishing on the server too.
	finish()
end

local function watchCharacter(character: Model)
	setTool(nil)
	character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") and child:GetAttribute("RodId") then
			setTool(child)
		end
	end)
	character.ChildRemoved:Connect(function(child)
		if child == currentTool then
			setTool(nil)
		end
	end)
	for _, child in character:GetChildren() do
		if child:IsA("Tool") and child:GetAttribute("RodId") then
			setTool(child)
		end
	end
end

local function buildUi()
	local screen = Kit.Screen("Fishing", 5)

	hintLabel = Kit.new("TextLabel", {
		Name = "Hint",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -96),
		Size = UDim2.fromOffset(0, 40),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = Theme.Colors.Dark,
		BackgroundTransparency = 0.25,
		Font = Theme.Font,
		TextSize = 24,
		TextColor3 = Theme.Colors.TextLight,
		Visible = false,
		Parent = screen,
	}, { Kit.Corner(UDim.new(0, 12)), Kit.Padding(0, 18, 0, 18) })

	biteScale = Kit.new("UIScale")
	bitePrompt = Kit.new("Frame", {
		Name = "Bite",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.62),
		Size = UDim2.fromOffset(260, 150),
		BackgroundTransparency = 1,
		Visible = false,
		Parent = screen,
	}, { biteScale })

	Kit.new("TextLabel", {
		Name = "Mark",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0),
		Size = UDim2.fromOffset(80, 80),
		BackgroundColor3 = Theme.Colors.Warning,
		Font = Theme.Font,
		Text = "!",
		TextSize = 60,
		TextColor3 = Theme.Colors.TextLight,
		Parent = bitePrompt,
	}, { Kit.Corner(UDim.new(1, 0)), Kit.Stroke(Theme.Colors.Stroke, 4), Kit.TextStroke(Theme.Colors.Stroke, 3) })

	Kit.new("TextLabel", {
		Name = "Action",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 86),
		Size = UDim2.fromOffset(260, 36),
		BackgroundTransparency = 1,
		Font = Theme.Font,
		Text = "CLICK NOW!",
		TextSize = 32,
		TextColor3 = Theme.Colors.TextLight,
		Parent = bitePrompt,
	}, { Kit.TextStroke(Theme.Colors.Stroke, 3) })

	local track = Kit.new("Frame", {
		Name = "Timer",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 128),
		Size = UDim2.fromOffset(200, 14),
		BackgroundColor3 = Theme.Colors.Dark,
		Parent = bitePrompt,
	}, { Kit.Corner(UDim.new(1, 0)), Kit.Stroke(Theme.Colors.Stroke, 2) })
	biteBar = Kit.new("Frame", {
		Name = "Fill",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Theme.Colors.Warning,
		Parent = track,
	}, { Kit.Corner(UDim.new(1, 0)) })

	CatchCard.Create(screen)
end

local function onFishingEvent(kind: string, payload: { [string]: any })
	if kind == "Bite" then
		state = "Biting"
		showBite(payload.Window or FishingConfig.ReelWindow)
		SoundPlayer.Play("Bite")
		updateHint()
	elseif kind == "Caught" then
		finish()
		SoundPlayer.Play("Catch")
		CatchCard.Show(payload.CreatureId, payload.Weight, payload.Value, payload.IsNew)
	elseif kind == "Escaped" then
		finish()
		SoundPlayer.Play("Escape")
		NotificationController:Show("It got away...", "Info")
	elseif kind == "Cancelled" then
		finish()
		local message = CANCEL_MESSAGES[payload.Reason]
		if message then
			NotificationController:Show(message, "Info")
		end
	end
end

function FishingController:Init()
	buildUi()
end

function FishingController:Start()
	Remotes.Event("FishingEvent").OnClientEvent:Connect(onFishingEvent)

	player.CharacterAdded:Connect(watchCharacter)
	if player.Character then
		watchCharacter(player.Character)
	end

	UserInputService.LastInputTypeChanged:Connect(updateHint)
	DataController.Loaded:Connect(updateHint)

	-- The "walk to the pond" / "cast" hint depends on where the player is standing.
	while true do
		task.wait(0.4)
		if currentTool and state == "Idle" then
			updateHint()
		end
	end
end

return FishingController
