--!strict
-- Positions on the circular map. The pond is at the origin; angle 0 is north (-Z), going clockwise.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MapConfig = require(ReplicatedStorage.Shared.Config.Map)

local Layout = {}

function Layout.PlotAngle(index: number): number
	return (index - 1) * (2 * math.pi / MapConfig.PlotCount)
end

function Layout.RingPoint(angle: number, radius: number, y: number): Vector3
	return Vector3.new(math.sin(angle) * radius, y, -math.cos(angle) * radius)
end

-- A CFrame at `position` facing the pond centre (level, no tilt).
function Layout.FacingPond(position: Vector3): CFrame
	return CFrame.lookAt(position, Vector3.new(0, position.Y, 0))
end

function Layout.HorizontalDistance(a: Vector3, b: Vector3): number
	return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude
end

return Layout
