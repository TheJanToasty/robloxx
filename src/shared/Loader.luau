--!strict
--[[
	Loads every ModuleScript under a folder and runs a two-phase lifecycle:

	1. Init()  - called on each module in order, one at a time. Use it to set up
	             state and grab references to other modules. Must not yield.
	2. Start() - called on each module in its own thread once every module has
	             finished Init. Use it for connections, loops and other runtime work.

	Both methods are optional. Modules load in alphabetical order.
]]

local Loader = {}

export type Module = {
	Init: ((self: any) -> ())?,
	Start: ((self: any) -> ())?,
	[any]: any,
}

function Loader.LoadChildren(parent: Instance): { [string]: Module }
	local children = parent:GetChildren()
	table.sort(children, function(a, b)
		return a.Name < b.Name
	end)

	local modules: { [string]: Module } = {}
	local order: { string } = {}

	for _, child in children do
		if child:IsA("ModuleScript") then
			modules[child.Name] = require(child) :: any
			table.insert(order, child.Name)
		end
	end

	for _, name in order do
		local module = modules[name]
		local init = module.Init
		if init then
			local ok, err = pcall(function()
				init(module)
			end)
			if not ok then
				error(`[Loader] {parent.Name}.{name}:Init() failed: {err}`, 0)
			end
		end
	end

	for _, name in order do
		local module = modules[name]
		if module.Start then
			task.spawn(module.Start, module)
		end
	end

	return modules
end

return Loader
