--!strict
--[[
	Server-authoritative fishing.

	1. The client asks to Cast. The server checks the player is holding their rod,
	   is near the pond, is facing the water and has backpack space, then throws a
	   bobber that everyone can see.
	2. After a random wait (faster with better rods) a creature bites. The server
	   tells the player and starts a short timer.
	3. The client asks to Reel. If the bite timer is still running, the server rolls
	   the creature (using the rod's Power and Luck), puts it in the backpack and
	   records it in the Index. Otherwise it gets away.

	The client never says what it caught or when the bite happened; it only says
	"cast" and "reel", and the server checks the timing itself.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage.Shared
local Catalog = require(Shared.Modules.Catalog)
local CatchMath = require(Shared.Modules.CatchMath)
local FishingConfig = require(Shared.Config.Fishing)
local MapConfig = require(Shared.Config.Map)
local Remotes = require(Shared.Modules.Remotes)
local DataService = require(script.Parent.DataService)
local IndexService = require(script.Parent.IndexService)
local InventoryService = require(script.Parent.InventoryService)
local MapService = require(script.Parent.MapService)
local NotificationService = require(script.Parent.NotificationService)
local RodService = require(script.Parent.RodService)

type Rod = Catalog.Rod

type Session = {
	Rod: Rod,
	Tool: Tool,
	State: "Casting" | "Waiting" | "Biting",
	Landing: Vector3,
	Bobber: BasePart,
	BiteAt: number,
	Connections: { RBXScriptConnection },
}

local FishingService = {}

local sessions: { [Player]: Session } = {}
local cooldowns: { [Player]: number } = {}
local rng = Random.new()

local function sendEvent(player: Player, kind: string, payload: { [string]: any }?)
	Remotes.Event("FishingEvent"):FireClient(player, kind, payload or {})
end

local function sendFx(kind: string, payload: { [string]: any })
	Remotes.Event("FishingFx"):FireAllClients(kind, payload)
end

local function horizontalDistance(a: Vector3, b: Vector3): number
	return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude
end

local function getCharacterParts(player: Player): (Model?, Humanoid?, BasePart?)
	local character = player.Character
	if not character then
		return nil, nil, nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not humanoid or humanoid.Health <= 0 or not root then
		return nil, nil, nil
	end
	return character, humanoid, root
end

local function endSession(player: Player)
	local session = sessions[player]
	if not session then
		return
	end
	sessions[player] = nil
	cooldowns[player] = os.clock() + FishingConfig.Cooldown
	for _, connection in session.Connections do
		connection:Disconnect()
	end
	session.Bobber:Destroy()
end

-- Where the bobber would land, or nil and a reason the player can't cast here.
local function getLanding(root: BasePart, rod: Rod): (Vector3?, string?)
	local pondCenter = MapService:GetPondCenter()
	local position = root.Position

	if horizontalDistance(position, pondCenter) > MapConfig.PondRadius + FishingConfig.MaxShoreDistance then
		return nil, "Get closer to the pond to fish!"
	end
	if position.Y < MapConfig.WaterSurfaceY - 1 then
		return nil, "You can't fish while swimming!"
	end

	local look = root.CFrame.LookVector
	local flat = Vector3.new(look.X, 0, look.Z)
	if flat.Magnitude < 0.1 then
		return nil, "Face the water to cast!"
	end
	flat = flat.Unit

	local landing = Vector3.new(position.X, MapConfig.WaterSurfaceY, position.Z) + flat * rod.CastDistance
	if horizontalDistance(landing, pondCenter) > MapConfig.PondRadius - FishingConfig.EdgePadding then
		return nil, "Face the water to cast!"
	end
	return landing, nil
end

local function makeBobber(tool: Tool, start: Vector3): BasePart
	local bobber = Instance.new("Part")
	bobber.Name = "Bobber"
	bobber.Shape = Enum.PartType.Ball
	bobber.Size = Vector3.new(0.8, 0.8, 0.8)
	bobber.Color = Color3.fromRGB(235, 60, 60)
	bobber.Material = Enum.Material.SmoothPlastic
	bobber.Anchored = true
	bobber.CanCollide = false
	bobber.CanQuery = false
	bobber.CanTouch = false
	bobber.CFrame = CFrame.new(start)

	local cap = Instance.new("Part")
	cap.Name = "Cap"
	cap.Shape = Enum.PartType.Ball
	cap.Size = Vector3.new(0.5, 0.5, 0.5)
	cap.Color = Color3.fromRGB(255, 255, 255)
	cap.Material = Enum.Material.SmoothPlastic
	cap.CanCollide = false
	cap.CanQuery = false
	cap.CanTouch = false
	cap.Massless = true
	cap.CFrame = bobber.CFrame * CFrame.new(0, 0.3, 0)
	cap.Parent = bobber
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = bobber
	weld.Part1 = cap
	weld.Parent = cap

	local lineEnd = Instance.new("Attachment")
	lineEnd.Name = "LineEnd"
	lineEnd.Position = Vector3.new(0, 0.4, 0)
	lineEnd.Parent = bobber

	local handle = tool:FindFirstChild("Handle") :: BasePart?
	local lineStart = handle and handle:FindFirstChild("LineAttachment") :: Attachment?
	if handle and not lineStart then
		local fallback = Instance.new("Attachment")
		fallback.Name = "LineAttachment"
		fallback.Parent = handle
		lineStart = fallback
	end
	if lineStart then
		local line = Instance.new("Beam")
		line.Name = "Line"
		line.Attachment0 = lineStart
		line.Attachment1 = lineEnd
		line.Width0 = 0.06
		line.Width1 = 0.06
		line.FaceCamera = true
		line.Segments = 12
		line.CurveSize0 = -1.5
		line.CurveSize1 = 1.5
		line.Color = ColorSequence.new(Color3.fromRGB(245, 245, 245))
		line.Transparency = NumberSequence.new(0.15)
		line.LightInfluence = 0
		line.Parent = bobber
	end

	bobber.Parent = MapService:GetFishingFolder()
	return bobber
end

-- Flies the bobber from the rod tip to the landing point in an arc.
local function throwBobber(bobber: BasePart, from: Vector3, to: Vector3)
	local progress = Instance.new("NumberValue")
	local arcHeight = math.max(4, (to - from).Magnitude * 0.3)
	progress.Changed:Connect(function(t: number)
		local position = from:Lerp(to, t) + Vector3.new(0, math.sin(t * math.pi) * arcHeight, 0)
		bobber.CFrame = CFrame.new(position)
	end)
	local tween = TweenService:Create(progress, TweenInfo.new(FishingConfig.CastTime, Enum.EasingStyle.Sine), {
		Value = 1,
	})
	tween.Completed:Once(function()
		progress:Destroy()
	end)
	tween:Play()
end

local function startBite(player: Player, session: Session)
	if sessions[player] ~= session then
		return
	end
	session.State = "Biting"
	session.BiteAt = os.clock()

	-- Bob the float under the water a few times.
	local dip = TweenService:Create(
		session.Bobber,
		TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 4, true),
		{ CFrame = CFrame.new(session.Landing - Vector3.new(0, 0.6, 0)) }
	)
	dip:Play()

	sendEvent(player, "Bite", { Window = FishingConfig.ReelWindow })
	sendFx("Bite", { Position = session.Landing })

	task.delay(FishingConfig.ReelWindow + FishingConfig.LatencyGrace, function()
		if sessions[player] == session and session.State == "Biting" then
			sendFx("Escape", { Position = session.Landing })
			endSession(player)
			sendEvent(player, "Escaped")
		end
	end)
end

function FishingService:Cast(player: Player): (boolean, string?)
	if sessions[player] then
		return false, nil
	end
	if os.clock() < (cooldowns[player] or 0) then
		return false, nil
	end

	local data = DataService:GetData(player)
	if not data then
		return false, "Still loading your data..."
	end

	local character, humanoid, root = getCharacterParts(player)
	if not character or not humanoid or not root then
		return false, nil
	end

	local tool = character:FindFirstChildOfClass("Tool")
	local rod = RodService:GetEquippedRod(player)
	if not tool or not rod or tool:GetAttribute("RodId") ~= rod.Id then
		return false, "Equip your fishing rod first!"
	end

	if InventoryService:IsFull(player) then
		return false, "Your backpack is full! Sell your catch at your plot."
	end

	local landing, reason = getLanding(root, rod)
	if not landing then
		return false, reason
	end

	local handle = tool:FindFirstChild("Handle") :: BasePart?
	local start = if handle then handle.Position else root.Position
	local bobber = makeBobber(tool, start)

	local session: Session = {
		Rod = rod,
		Tool = tool,
		State = "Casting",
		Landing = landing,
		Bobber = bobber,
		BiteAt = 0,
		Connections = {},
	}
	sessions[player] = session

	local function cancel()
		if sessions[player] == session then
			endSession(player)
			sendEvent(player, "Cancelled", { Reason = "Unequipped" })
		end
	end
	table.insert(
		session.Connections,
		tool.AncestryChanged:Connect(function()
			if tool.Parent ~= character then
				cancel()
			end
		end)
	)
	table.insert(session.Connections, humanoid.Died:Connect(cancel))

	throwBobber(bobber, start, landing)
	sendFx("Cast", { Position = start })

	task.delay(FishingConfig.CastTime, function()
		if sessions[player] ~= session then
			return
		end
		session.State = "Waiting"
		sendFx("Splash", { Position = landing })

		local wait = rng:NextNumber(FishingConfig.BiteTime.Min, FishingConfig.BiteTime.Max) / rod.Speed
		task.delay(wait, startBite, player, session)
	end)

	return true, nil
end

function FishingService:Reel(player: Player): (boolean, string?)
	local session = sessions[player]
	if not session then
		return false, nil
	end

	if session.State ~= "Biting" then
		-- Reeling in before a bite just pulls the line back.
		endSession(player)
		sendEvent(player, "Cancelled", { Reason = "Early" })
		return true, nil
	end

	local landing = session.Landing
	if os.clock() - session.BiteAt > FishingConfig.ReelWindow + FishingConfig.LatencyGrace then
		sendFx("Escape", { Position = landing })
		endSession(player)
		sendEvent(player, "Escaped")
		return true, nil
	end

	local data = DataService:GetData(player)
	local creature = data and CatchMath.Roll(session.Rod, data.Level, rng)
	endSession(player)
	if not data or not creature then
		return false, nil
	end

	local weight = CatchMath.RollWeight(creature, rng)
	local item = InventoryService:AddCreature(player, creature.Id, weight)
	if not item then
		return false, "Your backpack is full! Sell your catch at your plot."
	end

	local isNew = IndexService:Record(player, creature.Id, weight)
	data.Stats.TotalCaught += 1
	DataService:Replicate(player, "Stats")

	sendEvent(player, "Caught", {
		CreatureId = creature.Id,
		Weight = weight,
		Value = CatchMath.GetValue(creature, weight),
		IsNew = isNew,
	})
	sendFx("Catch", { UserId = player.UserId, CreatureId = creature.Id, From = landing })

	local rarity = Catalog.Rarities.ByName[creature.Rarity]
	if rarity.Announce then
		NotificationService:SendAll(`{player.DisplayName} caught a {rarity.Name} {creature.Name}!`, "Rare")
	end
	if InventoryService:IsFull(player) then
		NotificationService:Send(player, "Backpack full! Sell your catch at your plot.", "Error")
	end
	return true, nil
end

function FishingService:IsFishing(player: Player): boolean
	return sessions[player] ~= nil
end

function FishingService:Init()
	Remotes.Function("FishingAction").OnServerInvoke = function(player: Player, action: unknown)
		if action == "Cast" then
			return self:Cast(player)
		elseif action == "Reel" then
			return self:Reel(player)
		end
		return false, nil
	end
end

function FishingService:Start()
	Players.PlayerRemoving:Connect(function(player)
		endSession(player)
		cooldowns[player] = nil
	end)

	-- Reel in automatically if a player walks too far from their bobber.
	while true do
		task.wait(0.5)
		for player, session in sessions do
			local _, _, root = getCharacterParts(player)
			local limit = session.Rod.CastDistance + FishingConfig.MaxLineSlack
			if not root or horizontalDistance(root.Position, session.Landing) > limit then
				endSession(player)
				sendEvent(player, "Cancelled", { Reason = "TooFar" })
			end
		end
	end
end

return FishingService
