--!strict
-- Sends on-screen messages to players. Kinds: "Info", "Success", "Error", "Rare".

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Modules.Remotes)

export type Kind = "Info" | "Success" | "Error" | "Rare"

local NotificationService = {}

function NotificationService:Send(player: Player, message: string, kind: Kind?)
	Remotes.Event("Notify"):FireClient(player, message, kind or "Info")
end

function NotificationService:SendAll(message: string, kind: Kind?)
	Remotes.Event("Notify"):FireAllClients(message, kind or "Info")
end

return NotificationService
