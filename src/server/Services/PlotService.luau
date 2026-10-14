--!strict
--[[
	Gives each player one of the 8 plots when they join and frees it when they
	leave. Players spawn (and respawn) on their own plot.

	Plot ownership is server-only. Clients can read it from the plot model's
	"OwnerUserId" attribute and the player's "PlotIndex" attribute, but can't change it.
]]

local Players = game:GetService("Players")

local MapService = require(script.Parent.MapService)

type Plot = MapService.Plot

local PlotService = {}

local owners: { [Plot]: Player } = {}
local playerPlots: { [Player]: Plot } = {}

local function claimPlot(player: Player): Plot?
	for _, plot in MapService:GetPlots() do
		if not owners[plot] then
			owners[plot] = player
			playerPlots[player] = plot
			plot.Model:SetAttribute("OwnerUserId", player.UserId)
			plot.SignLabel.Text = `{player.DisplayName}'s Plot`
			player:SetAttribute("PlotIndex", plot.Index)
			return plot
		end
	end
	return nil
end

local function releasePlot(player: Player)
	local plot = playerPlots[player]
	if not plot then
		return
	end
	playerPlots[player] = nil
	owners[plot] = nil
	plot.Model:SetAttribute("OwnerUserId", 0)
	plot.SignLabel.Text = "Free Plot"
end

local function spawnCharacter(player: Player)
	if player.Parent then
		local ok, err = pcall(function()
			player:LoadCharacterAsync()
		end)
		if not ok and tostring(err):find("not a valid member") then
			-- Older engine versions only have the original method.
			ok, err = pcall(function()
				(player :: any):LoadCharacter()
			end)
		end
		if not ok then
			warn(`[PlotService] Couldn't spawn {player.Name}: {err}`)
		end
	end
end

local function onCharacterAdded(player: Player, character: Model)
	local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
	local root = character:WaitForChild("HumanoidRootPart", 10) :: BasePart?
	if not humanoid or not root then
		return
	end

	-- RespawnLocation normally handles this; move them if they still ended up elsewhere.
	local spawn = player.RespawnLocation
	if spawn and (root.Position - spawn.Position).Magnitude > 20 then
		character:PivotTo(spawn.CFrame + Vector3.new(0, 4, 0))
	end

	humanoid.Died:Once(function()
		task.wait(Players.RespawnTime)
		if player.Parent and player.Character == character then
			spawnCharacter(player)
		end
	end)
end

local function onPlayerAdded(player: Player)
	local plot = claimPlot(player)
	player.RespawnLocation = if plot then plot.Spawn else MapService:GetHubSpawn()

	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)
	spawnCharacter(player)
end

-- The plot this player owns, if any.
function PlotService:GetPlot(player: Player): Plot?
	return playerPlots[player]
end

-- True if the player's character is within `range` studs of `part`.
function PlotService:IsNear(player: Player, part: BasePart, range: number): boolean
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	return root ~= nil and (root.Position - part.Position).Magnitude <= range
end

function PlotService:Init()
	-- We spawn characters ourselves so they appear on their plot.
	Players.CharacterAutoLoads = false
end

function PlotService:Start()
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(releasePlot)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end
end

return PlotService
