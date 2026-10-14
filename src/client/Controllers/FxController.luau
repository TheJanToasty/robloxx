--!strict
--[[
	Fishing effects every player sees: splashes, ripples, and caught creatures
	leaping out of the water to whoever caught them. All of this is local
	decoration only, created on each client from the server's FishingFx events.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Catalog = require(Shared.Modules.Catalog)
local CreatureModel = require(Shared.Modules.CreatureModel)
local Remotes = require(Shared.Modules.Remotes)
local SoundPlayer = require(script.Parent.Parent.Modules.SoundPlayer)
local Kit = require(script.Parent.Parent.UI.Kit)

local FxController = {}

local folder: Folder

local SPLASH_TEXTURE = "rbxasset://textures/particles/smoke_main.dds"
local SPARKLE_TEXTURE = "rbxasset://textures/particles/sparkles_main.dds"

local function emitAt(position: Vector3, count: number, properties: { [string]: any }, lifetime: number)
	local attachment = Instance.new("Attachment")
	attachment.WorldPosition = position
	attachment.Parent = Workspace.Terrain
	local emitter = Instance.new("ParticleEmitter")
	emitter.Enabled = false
	for key, value in properties do
		(emitter :: any)[key] = value
	end
	emitter.Parent = attachment
	emitter:Emit(count)
	task.delay(lifetime + 0.5, function()
		attachment:Destroy()
	end)
end

local function splash(position: Vector3, strength: number)
	emitAt(position, math.floor(14 * strength), {
		Texture = SPLASH_TEXTURE,
		Color = ColorSequence.new(Color3.fromRGB(220, 245, 255)),
		Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.5 * strength),
			NumberSequenceKeypoint.new(1, 0),
		}),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.1),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Lifetime = NumberRange.new(0.4, 0.8),
		Speed = NumberRange.new(6 * strength, 12 * strength),
		SpreadAngle = Vector2.new(30, 30),
		Acceleration = Vector3.new(0, -35, 0),
		EmissionDirection = Enum.NormalId.Top,
		LightInfluence = 0.5,
	}, 0.8)
end

local function ripple(position: Vector3, size: number)
	local ring = Instance.new("Part")
	ring.Name = "Ripple"
	ring.Shape = Enum.PartType.Cylinder
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanQuery = false
	ring.CanTouch = false
	ring.Material = Enum.Material.SmoothPlastic
	ring.Color = Color3.fromRGB(235, 250, 255)
	ring.Transparency = 0.35
	ring.Size = Vector3.new(0.05, 1, 1)
	ring.CFrame = CFrame.new(position + Vector3.new(0, 0.05, 0)) * CFrame.Angles(0, 0, math.pi / 2)
	ring.Parent = folder
	Kit.Tween(ring, 0.9, { Size = Vector3.new(0.05, size, size), Transparency = 1 })
	task.delay(1, function()
		ring:Destroy()
	end)
end

local function sparkleBurst(position: Vector3, color: Color3)
	emitAt(position, 30, {
		Texture = SPARKLE_TEXTURE,
		Color = ColorSequence.new(color),
		Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.8),
			NumberSequenceKeypoint.new(1, 0),
		}),
		Lifetime = NumberRange.new(0.6, 1.2),
		Speed = NumberRange.new(8, 16),
		SpreadAngle = Vector2.new(180, 180),
		LightEmission = 1,
	}, 1.2)
end

-- The caught creature jumps out of the water in an arc and lands on the catcher's head.
local function leap(creatureId: string, from: Vector3, userId: number)
	local creature = Catalog.Creatures.ById[creatureId]
	local catcher = Players:GetPlayerByUserId(userId)
	local character = catcher and catcher.Character
	local head = character and character:FindFirstChild("Head") :: BasePart?
	if not creature or not head then
		return
	end

	local model = CreatureModel.Build(creature)
	model.Parent = folder

	local duration = 0.75
	local started = os.clock()
	local connection: RBXScriptConnection
	connection = RunService.RenderStepped:Connect(function()
		local t = math.min((os.clock() - started) / duration, 1)
		local target = if head.Parent then head.Position + Vector3.new(0, 3, 0) else from
		local position = from:Lerp(target, t) + Vector3.new(0, math.sin(t * math.pi) * 8, 0)
		local spin = CFrame.Angles(0, t * math.pi * 4, 0)
		model:PivotTo(CFrame.new(position) * spin)
		if t >= 1 then
			connection:Disconnect()
			task.delay(0.35, function()
				model:Destroy()
			end)
		end
	end)
end

local function onFx(kind: string, payload: { [string]: any })
	local position: Vector3? = payload.Position
	if kind == "Cast" and position then
		SoundPlayer.Play("Cast", position)
	elseif kind == "Splash" and position then
		splash(position, 0.6)
		ripple(position, 5)
		SoundPlayer.Play("Splash", position)
	elseif kind == "Bite" and position then
		splash(position, 0.9)
		ripple(position, 7)
	elseif kind == "Escape" and position then
		ripple(position, 4)
		SoundPlayer.Play("Escape", position)
	elseif kind == "Catch" then
		local from: Vector3 = payload.From
		splash(from, 1.4)
		ripple(from, 10)
		SoundPlayer.Play("Splash", from)
		local creature = Catalog.Creatures.ById[payload.CreatureId]
		if creature then
			local rarity = Catalog.Rarities.ByName[creature.Rarity]
			if rarity.Tier >= 3 then
				sparkleBurst(from + Vector3.new(0, 2, 0), rarity.Color)
			end
		end
		leap(payload.CreatureId, from, payload.UserId)
	end
end

function FxController:Init()
	folder = Instance.new("Folder")
	folder.Name = "LocalEffects"
	folder.Parent = Workspace
end

function FxController:Start()
	Remotes.Event("FishingFx").OnClientEvent:Connect(onFx)
end

return FxController
