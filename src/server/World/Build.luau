--!strict
-- Small helpers for creating map parts from code.

local Build = {}

-- Creates an anchored part. Pass any Part properties; Parent is applied last.
function Build.Part(properties: { [string]: any }): Part
	local part = Instance.new("Part")
	part.Anchored = true
	part.Material = Enum.Material.Plastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	local parent = properties.Parent
	for key, value in properties do
		if key ~= "Parent" then
			(part :: any)[key] = value
		end
	end
	part.Parent = parent
	return part
end

-- Same as Build.Part, with classic Roblox studs on top.
function Build.Studded(properties: { [string]: any }): Part
	local part = Build.Part(properties)
	part.TopSurface = Enum.SurfaceType.Studs
	return part
end

-- A part that is only for looks: no collisions, raycasts or touch events.
function Build.Decoration(properties: { [string]: any }): Part
	local part = Build.Part(properties)
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	return part
end

function Build.Model(name: string, parent: Instance): Model
	local model = Instance.new("Model")
	model.Name = name
	model.Parent = parent
	return model
end

function Build.Folder(name: string, parent: Instance): Folder
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder
end

-- A SurfaceGui with one big label, for signs.
function Build.SignText(part: BasePart, face: Enum.NormalId, text: string, color: Color3?): TextLabel
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.LightInfluence = 0
	gui.MaxDistance = 300

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.FredokaOne
	label.Text = text
	label.TextScaled = true
	label.TextColor3 = color or Color3.new(1, 1, 1)
	label.Parent = gui

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0.06, 0)
	padding.PaddingRight = UDim.new(0.06, 0)
	padding.PaddingTop = UDim.new(0.12, 0)
	padding.PaddingBottom = UDim.new(0.12, 0)
	padding.Parent = label

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Color = Color3.fromRGB(40, 40, 60)
	stroke.Transparency = 0.2
	stroke.Parent = label

	gui.Parent = part
	return label
end

-- Darkens (amount > 0) or lightens (amount < 0) a colour.
function Build.Shade(color: Color3, amount: number): Color3
	if amount >= 0 then
		return color:Lerp(Color3.new(0, 0, 0), amount)
	end
	return color:Lerp(Color3.new(1, 1, 1), -amount)
end

return Build
