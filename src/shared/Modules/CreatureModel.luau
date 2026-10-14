--!strict
--[[
	Builds a creature's model from its config, so every creature has a look
	without any uploaded models: a round shell, a head with a long snout, big eyes
	and antennae, plus optional glow, crown and sparkles.

	To use a custom model, put a Model named after the creature's Model field (or
	Id) in ReplicatedStorage.Assets.Creatures. It should have a PrimaryPart.

	Models face -Z (forward) and are anchored with collisions off, ready for
	viewports and effects.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Catalog = require(script.Parent.Catalog)

type Creature = Catalog.Creature

local CreatureModel = {}

local EYE_WHITE = Color3.fromRGB(255, 255, 255)
local PUPIL = Color3.fromRGB(25, 25, 35)

local function part(model: Model, name: string, properties: { [string]: any }): Part
	local newPart = Instance.new("Part")
	newPart.Name = name
	newPart.Anchored = true
	newPart.CanCollide = false
	newPart.CanQuery = false
	newPart.CanTouch = false
	newPart.Massless = true
	newPart.TopSurface = Enum.SurfaceType.Smooth
	newPart.BottomSurface = Enum.SurfaceType.Smooth
	newPart.Material = Enum.Material.SmoothPlastic
	for key, value in properties do
		(newPart :: any)[key] = value
	end
	newPart.Parent = model
	return newPart
end

local function shade(color: Color3, amount: number): Color3
	return color:Lerp(Color3.new(0, 0, 0), amount)
end

local function findCustomModel(creature: Creature): Model?
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local folder = assets and assets:FindFirstChild("Creatures")
	local custom = folder and folder:FindFirstChild(creature.Model or creature.Id)
	if custom and custom:IsA("Model") and custom.PrimaryPart then
		return custom:Clone()
	end
	return nil
end

local function buildWeevil(creature: Creature): Model
	local look = creature.Look
	local s = look.Scale or 1
	local material = look.Material or Enum.Material.SmoothPlastic

	local model = Instance.new("Model")
	local origin = CFrame.new()

	local body = part(model, "Body", {
		Shape = Enum.PartType.Ball,
		Size = Vector3.one * 2.4 * s,
		Color = look.Body,
		Material = material,
		CFrame = origin,
	})
	model.PrimaryPart = body

	-- A darker ridge running front to back down the middle of the shell.
	part(model, "Stripe", {
		Size = Vector3.new(0.25, 2.5, 2.5) * s,
		Shape = Enum.PartType.Cylinder,
		Color = shade(look.Body, 0.25),
		Material = material,
		CFrame = origin,
	})

	local headFrame = origin * CFrame.new(0, 0.35 * s, -1.3 * s)
	part(model, "Head", {
		Shape = Enum.PartType.Ball,
		Size = Vector3.one * 1.5 * s,
		Color = shade(look.Body, 0.1),
		Material = material,
		CFrame = headFrame,
	})

	-- The long weevil snout, angled down.
	part(model, "Snout", {
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(1.6, 0.45, 0.45) * s,
		Color = look.Snout,
		-- Cylinders run along X: turn to point forward (-Z), then tilt the tip down.
		CFrame = headFrame
			* CFrame.new(0, -0.35 * s, -0.95 * s)
			* CFrame.Angles(0, math.pi / 2, 0)
			* CFrame.Angles(0, 0, math.rad(-25)),
	})

	for _, side in { -1, 1 } do
		local eyeFrame = headFrame * CFrame.new(side * 0.4 * s, 0.3 * s, -0.5 * s)
		part(model, "Eye", {
			Shape = Enum.PartType.Ball,
			Size = Vector3.one * 0.6 * s,
			Color = EYE_WHITE,
			CFrame = eyeFrame,
		})
		part(model, "Pupil", {
			Shape = Enum.PartType.Ball,
			Size = Vector3.one * 0.3 * s,
			Color = PUPIL,
			CFrame = eyeFrame * CFrame.new(0, 0, -0.2 * s),
		})

		-- Antennae: a thin stalk with a ball on the end.
		local stalkBase = headFrame * CFrame.new(side * 0.3 * s, 0.6 * s, -0.1 * s)
		local stalk = stalkBase * CFrame.Angles(math.rad(-20), 0, math.rad(-side * 25)) * CFrame.new(0, 0.5 * s, 0)
		part(model, "Antenna", {
			Size = Vector3.new(0.12, 1, 0.12) * s,
			Color = look.Snout,
			CFrame = stalk,
		})
		part(model, "AntennaTip", {
			Shape = Enum.PartType.Ball,
			Size = Vector3.one * 0.3 * s,
			Color = look.Glow or look.Snout,
			Material = if look.Glow then Enum.Material.Neon else Enum.Material.SmoothPlastic,
			CFrame = stalk * CFrame.new(0, 0.55 * s, 0),
		})

		-- Three little legs per side.
		for leg = -1, 1 do
			part(model, "Leg", {
				Size = Vector3.new(0.18, 0.7, 0.18) * s,
				Color = shade(look.Body, 0.35),
				CFrame = origin
					* CFrame.new(side * 0.95 * s, -1 * s, leg * 0.6 * s)
					* CFrame.Angles(0, 0, math.rad(side * 25)),
			})
		end
	end

	if look.Crown then
		local crownFrame = headFrame * CFrame.new(0, 0.85 * s, 0)
		part(model, "Crown", {
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.4, 0.9, 0.9) * s,
			Color = Color3.fromRGB(255, 210, 60),
			Material = Enum.Material.Foil,
			CFrame = crownFrame * CFrame.Angles(0, 0, math.pi / 2),
		})
		for point = 0, 4 do
			local angle = point / 5 * math.pi * 2
			part(model, "CrownPoint", {
				Size = Vector3.new(0.18, 0.4, 0.18) * s,
				Color = Color3.fromRGB(255, 210, 60),
				Material = Enum.Material.Foil,
				CFrame = crownFrame * CFrame.new(math.cos(angle) * 0.38 * s, 0.35 * s, math.sin(angle) * 0.38 * s),
			})
		end
	end

	if look.Glow then
		local light = Instance.new("PointLight")
		light.Color = look.Glow
		light.Range = 8 * s
		light.Brightness = 1.5
		light.Parent = body
	end

	if look.Sparkles then
		local emitter = Instance.new("ParticleEmitter")
		emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		emitter.Rate = 12
		emitter.Lifetime = NumberRange.new(0.6, 1.2)
		emitter.Speed = NumberRange.new(1, 2)
		emitter.SpreadAngle = Vector2.new(180, 180)
		emitter.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.3),
			NumberSequenceKeypoint.new(1, 0),
		})
		emitter.LightEmission = 1
		emitter.Color = ColorSequence.new(look.Glow or Color3.new(1, 1, 1))
		emitter.Parent = body
	end

	return model
end

-- A new model of this creature, named after it.
function CreatureModel.Build(creature: Creature): Model
	local model = findCustomModel(creature) or buildWeevil(creature)
	model.Name = creature.Name
	return model
end

return CreatureModel
