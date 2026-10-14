--!strict
-- Bright, colourful daytime lighting.

local Lighting = game:GetService("Lighting")

local Environment = {}

local function replace(className: string, name: string): Instance
	local existing = Lighting:FindFirstChildOfClass(className)
	if existing then
		existing:Destroy()
	end
	local instance = Instance.new(className)
	instance.Name = name
	return instance
end

function Environment.Apply()
	Lighting.ClockTime = 14.5
	Lighting.Brightness = 2.2
	Lighting.Ambient = Color3.fromRGB(96, 96, 112)
	Lighting.OutdoorAmbient = Color3.fromRGB(150, 150, 165)
	Lighting.EnvironmentDiffuseScale = 0.6
	Lighting.EnvironmentSpecularScale = 0.6
	Lighting.GlobalShadows = true
	Lighting.ShadowSoftness = 0.3

	if not Lighting:FindFirstChildOfClass("Sky") then
		local sky = Instance.new("Sky")
		sky.Parent = Lighting
	end

	local atmosphere = replace("Atmosphere", "Atmosphere") :: Atmosphere
	atmosphere.Density = 0.28
	atmosphere.Offset = 0.2
	atmosphere.Color = Color3.fromRGB(205, 232, 255)
	atmosphere.Decay = Color3.fromRGB(120, 180, 255)
	atmosphere.Glare = 0
	atmosphere.Haze = 0.8
	atmosphere.Parent = Lighting

	local color = replace("ColorCorrectionEffect", "ColorCorrection") :: ColorCorrectionEffect
	color.Saturation = 0.15
	color.Contrast = 0.05
	color.Brightness = 0.02
	color.Parent = Lighting

	local bloom = replace("BloomEffect", "Bloom") :: BloomEffect
	bloom.Intensity = 0.35
	bloom.Size = 24
	bloom.Threshold = 1.6
	bloom.Parent = Lighting

	local sunRays = replace("SunRaysEffect", "SunRays") :: SunRaysEffect
	sunRays.Intensity = 0.04
	sunRays.Spread = 0.6
	sunRays.Parent = Lighting
end

return Environment
