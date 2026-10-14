--!strict
-- Shows a model inside a ViewportFrame, framed so the whole thing fits.

local Viewport = {}

-- `direction` is where the camera sits relative to the model (models face -Z).
function Viewport.Show(frame: ViewportFrame, model: Model, direction: Vector3?)
	for _, child in frame:GetChildren() do
		if child:IsA("Model") or child:IsA("BasePart") then
			child:Destroy()
		end
	end

	local camera = frame.CurrentCamera
	if not camera then
		local newCamera = Instance.new("Camera")
		newCamera.FieldOfView = 40
		newCamera.Parent = frame
		frame.CurrentCamera = newCamera
		camera = newCamera
	end
	assert(camera)

	model:PivotTo(CFrame.new())
	model.Parent = frame

	local boxCFrame, size = model:GetBoundingBox()
	local radius = size.Magnitude / 2
	local distance = radius / math.tan(math.rad(camera.FieldOfView / 2)) * 1.05
	local offset = (direction or Vector3.new(-0.7, 0.5, -1)).Unit * distance
	camera.CFrame = CFrame.lookAt(boxCFrame.Position + offset, boxCFrame.Position)
end

return Viewport
