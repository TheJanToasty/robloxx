--!strict
--[[
	Shows the Sell and Shop prompts only on the local player's own plot.
	This is just for a tidy screen: the server still checks plot ownership on every
	sale and purchase.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer

local PlotController = {}

local function refreshPlot(plot: Instance)
	local isMine = plot:GetAttribute("OwnerUserId") == player.UserId
	for _, descendant in plot:GetDescendants() do
		if descendant:IsA("ProximityPrompt") then
			descendant.Enabled = isMine
		end
	end
end

-- The local player's plot model, or nil.
function PlotController:GetMyPlot(): Model?
	local index = player:GetAttribute("PlotIndex")
	local map = Workspace:FindFirstChild("Map")
	local plots = map and map:FindFirstChild("Plots")
	local plot = plots and index and plots:FindFirstChild(`Plot{index}`)
	return if plot and plot:IsA("Model") then plot else nil
end

function PlotController:Start()
	local map = Workspace:WaitForChild("Map")
	local plots = map:WaitForChild("Plots")

	local function watch(plot: Instance)
		refreshPlot(plot)
		plot:GetAttributeChangedSignal("OwnerUserId"):Connect(function()
			refreshPlot(plot)
		end)
		-- With streaming on, parts of the plot can arrive after the model does.
		plot.DescendantAdded:Connect(function(descendant)
			if descendant:IsA("ProximityPrompt") then
				descendant.Enabled = plot:GetAttribute("OwnerUserId") == player.UserId
			end
		end)
	end

	plots.ChildAdded:Connect(watch)
	for _, plot in plots:GetChildren() do
		watch(plot)
	end
end

return PlotController
