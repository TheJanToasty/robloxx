# Fish a Weevil

A colourful Roblox fishing and progression game with a classic studded look. Players fish in a big central pond, fill their backpack with weevil-like creatures, sell them at their plot, and spend coins on better rods and bigger backpacks.

GitHub is the source of truth. Code syncs into Roblox Studio with [Rojo](https://rojo.space). Don't make important scripts directly in Studio; they won't be saved here.

## Setup

1. Install [Rokit](https://github.com/rojo-rbx/rokit), then run `rokit install` in this folder. That installs Rojo, Selene and StyLua at the versions in `rokit.toml`.
2. Run `rojo plugin install` to install the matching Rojo plugin, then restart Studio.
3. Run `rojo serve` here and click **Connect** in the Studio Rojo plugin.
4. Press **Play**. The map is built by code when the game starts, so edit mode looks empty.

To get the latest changes: `git pull` (or the sync button in VS Code). Rojo updates Studio automatically while it's connected.

To test saving in Studio: publish the place, then turn on **Game Settings → Security → Enable Studio Access to API Services**. Without that, players get temporary data and Output says so.

## How to play (Phase 1)

1. You spawn on your own plot (one of 8 around the pond).
2. Press **1** to hold your rod, walk to the pond (the docks are good spots) and face the water.
3. Click (tap on mobile, R2 on controller) to cast. When the **!** appears, click again quickly to reel in.
4. Your catch goes in your backpack (the left side of the screen; **B** opens it).
5. Go back to your plot and use the **SELL** stand to turn your catch into coins.
6. Use the **SHOP** stand to buy better rods (rarer creatures, faster bites) and bigger backpacks.

## Project layout

| Folder | Syncs to | What's in it |
| --- | --- | --- |
| `src/shared/Config` | `ReplicatedStorage.Shared.Config` | All game data: creatures, rarities, rods, upgrades, currencies, fishing rules, map layout, sounds |
| `src/shared/Data` | `ReplicatedStorage.Shared.Data` | The player data template (what gets saved) |
| `src/shared/Modules` | `ReplicatedStorage.Shared.Modules` | Shared code: `Catalog` (config lookup and checks), `CatchMath`, `Remotes`, model builders, helpers |
| `src/server/Services` | `ServerScriptService.Server.Services` | One module per server system, loaded automatically |
| `src/server/World` | `ServerScriptService.Server.World` | Builders for the map: ground, pond, plots, decorations, lighting |
| `src/client/Controllers` | `StarterPlayerScripts.Client.Controllers` | One module per client system, loaded automatically |
| `src/client/UI` | `StarterPlayerScripts.Client.UI` | UI helpers, theme and reusable pieces (window, catch card) |
| `src/client/Modules` | `StarterPlayerScripts.Client.Modules` | Other client helpers (sound player) |

### Server services

| Service | Job |
| --- | --- |
| `DataService` | Loads/saves player data with session locking, autosave and safe shutdown. Sends data to the owning client. |
| `MapService` | Builds the world from `Config/Map` when the server starts. |
| `PlotService` | Gives each player a plot and spawns them there. |
| `RodService` | Gives the equipped rod as a Tool and handles equipping. |
| `FishingService` | Cast, bite and reel. Decides every catch on the server. |
| `InventoryService` | The backpack and its capacity. |
| `IndexService` | Records every species a player has caught (for the Index in Phase 2). |
| `SellService` | The SELL stand. |
| `ShopService` | Validates and applies purchases. |
| `CurrencyService` | The only place coins are added or spent. |
| `UpgradeService` | Upgrade levels (backpack size, and future upgrades). |
| `NotificationService` | On-screen messages. |

### Rules the code follows

- The server decides everything that matters (catches, coins, purchases). Clients only ask.
- Every remote is declared in `src/shared/Modules/Remotes.luau`.
- Game data lives in `src/shared/Config`, never inside systems.
- New fields in player data are added to `PlayerDataTemplate`, and existing saves pick them up automatically.

## Adding content

- **New creature:** add an entry to `src/shared/Config/Creatures.luau` with a unique `Id`, a `Rarity`, `SellValue`, `CatchWeight`, `Weight` range and `Look` colours. It can be caught straight away.
- **New rod:** add an entry to `src/shared/Config/Rods.luau`. It appears in the shop automatically.
- **New upgrade level or track:** edit `src/shared/Config/Upgrades.luau`. New tracks appear in the shop; read their value with `UpgradeService:GetValue(player, "TrackId")`.
- **New currency:** add it to `src/shared/Config/Currencies.luau`.
- **Custom models:** put a Model in `ReplicatedStorage.Assets.Creatures` (named after the creature's `Model` or `Id`) or a Tool in `ReplicatedStorage.Assets.Rods` (named after the rod's `Id`), and it replaces the generated one.

Never rename or remove an `Id` once the game is live: player saves refer to it.

## Adding a system

Create a ModuleScript in `src/server/Services` (server) or `src/client/Controllers` (client). The entry script loads it automatically:

```lua
local MyService = {}

function MyService:Init()
	-- Runs first, one module at a time. Set up state here. Don't yield.
end

function MyService:Start()
	-- Runs after every module has finished Init. Connect events and start loops here.
end

return MyService
```

`Init` and `Start` are both optional. Modules load in alphabetical order. To use another service, `require(script.Parent.OtherService)`.

## Tooling

- `selene src` lints the code.
- `stylua src` formats it (`stylua --check src` only checks).

## Roadmap

- **Phase 1 (now):** map, plots, fishing, backpack, selling, coins, shop, rod and backpack upgrades, saving.
- **Phase 2:** more creatures and rods, XP and levels, the creature Index screen, better shop and feedback.
- **Phase 3:** rebirth, special fishing mechanics, plot progression, events, more currencies and upgrades.
- **Phase 4:** animations, VFX, audio, environment, mobile/controller polish, performance.
