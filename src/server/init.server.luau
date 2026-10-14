--!strict
-- Server entry point. Loads every service in the Services folder.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Loader = require(ReplicatedStorage.Shared.Loader)

Loader.LoadChildren(script.Services)
