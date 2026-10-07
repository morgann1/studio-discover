--!strict

const ServerScriptService = game:GetService("ServerScriptService")
const StarterPlayer = game:GetService("StarterPlayer")

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const gameFolder = require(StudioDiscover.Libraries.NevermoreRegistry.gameFolder)
const getOrCreateFolder = require(StudioDiscover.Libraries.Core.getOrCreateFolder)
const setScriptSourceAsync = require(StudioDiscover.Libraries.Core.setScriptSourceAsync)

-- The bootstrap Nevermore's install guide gives a game, which finds the loader among the packages.
const SERVER_MAIN = table.concat({
	"--!strict",
	'local ServerScriptService = game:GetService("ServerScriptService")',
	"",
	`local root = ServerScriptService.{gameFolder.NAME}`,
	'local loader = root:FindFirstChild("LoaderUtils", true).Parent',
	"local require = require(loader).bootstrapGame(root)",
	"",
}, "\n")

-- The loader copies the game folder into ReplicatedStorage, and the client bootstraps from that copy.
const CLIENT_MAIN = table.concat({
	"--!strict",
	'local ReplicatedStorage = game:GetService("ReplicatedStorage")',
	"",
	`local loader = ReplicatedStorage:WaitForChild("{gameFolder.NAME}"):WaitForChild("loader")`,
	"local require = require(loader).bootstrapGame(loader.Parent)",
	"",
}, "\n")

-- Adds `className` named `name` under `parent` with `source`, unless something already has the name.
const function addScriptAsync(
	parent: Instance,
	className: "Script" | "LocalScript",
	name: string,
	source: string
): string?
	if parent:FindFirstChild(name) ~= nil then
		return nil
	end

	const script: LuaSourceContainer = if className == "Script"
		then Instance.new("Script")
		else Instance.new("LocalScript")
	script.Name = name
	script.Parent = parent

	const ok, err = setScriptSourceAsync(script, source)
	if not ok then
		script:Destroy()
		return `{name}: {err}`
	end

	return nil
end

--[[
	Lays out a game for Nevermore the way `nevermore init` does: the game folder, with
		`game` split into Client, Server, and Shared, and `node_modules`, plus the
		ServerMain and ClientMain scripts that bootstrap the loader. Anything already
		there is left alone, and the user owns all of it afterwards.

	Returns the error when a script's source fails to write. Run it inside a
		ChangeHistory recording.
]]
const function setUpGameAsync(): string?
	const root = getOrCreateFolder(ServerScriptService, gameFolder.NAME)
	const modules = getOrCreateFolder(root, "game")
	for _, name in { "Client", "Server", "Shared" } do
		getOrCreateFolder(modules, name)
	end
	gameFolder.getNodeModules()

	const serverScripts = getOrCreateFolder(ServerScriptService, `{gameFolder.NAME}Scripts`)
	const serverError = addScriptAsync(serverScripts, "Script", "ServerMain", SERVER_MAIN)
	if serverError ~= nil then
		return serverError
	end

	const playerScripts = StarterPlayer:FindFirstChildOfClass("StarterPlayerScripts")
	if playerScripts == nil then
		return "StarterPlayer has no StarterPlayerScripts for ClientMain"
	end

	const clientScripts = getOrCreateFolder(playerScripts, `{gameFolder.NAME}Scripts`)
	return addScriptAsync(clientScripts, "LocalScript", "ClientMain", CLIENT_MAIN)
end

return setUpGameAsync
