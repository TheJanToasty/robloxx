--!strict
-- Client entry point. Loads every controller in the Controllers folder.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Loader = require(Shared:WaitForChild("Loader"))

Loader.LoadChildren(script:WaitForChild("Controllers"))
