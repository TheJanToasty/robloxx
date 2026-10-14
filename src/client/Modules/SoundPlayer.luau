--!strict
-- Plays the sound effects listed in Config/Sounds, either for the local player only or at a point in the world.

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")

local Sounds = require(ReplicatedStorage:WaitForChild("Shared").Config.Sounds)

local SoundPlayer = {}

-- Plays a sound by its name in Config/Sounds. With a position, it's heard in 3D from that spot.
function SoundPlayer.Play(name: string, position: Vector3?)
	local info = (Sounds :: any)[name]
	if not info or info.Id == "" then
		return
	end

	local sound = Instance.new("Sound")
	sound.SoundId = info.Id
	sound.Volume = info.Volume or 0.5
	sound.PlaybackSpeed = info.Pitch or 1

	local holder: Instance
	if position then
		local attachment = Instance.new("Attachment")
		attachment.WorldPosition = position
		attachment.Parent = Workspace.Terrain
		sound.RollOffMinDistance = 10
		sound.RollOffMaxDistance = 140
		holder = attachment
	else
		holder = sound
	end
	sound.Parent = if position then holder else SoundService
	sound:Play()

	sound.Ended:Once(function()
		holder:Destroy()
	end)
	-- In case the sound fails to load and never ends.
	Debris:AddItem(holder, 6)
end

return SoundPlayer
