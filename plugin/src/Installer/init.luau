--!strict

local installAsync = require(script.installAsync)
local uninstallAsync = require(script.uninstallAsync)
local updateAllAsync = require(script.updateAllAsync)
local useInstalledRoots = require(script.useInstalledRoots)
local useInstaller = require(script.useInstaller)
local useIsBusy = require(script.useIsBusy)
local useUpdates = require(script.useUpdates)

return table.freeze({
	installAsync = installAsync,
	uninstallAsync = uninstallAsync,
	updateAllAsync = updateAllAsync,
	useInstalledRoots = useInstalledRoots,
	useInstaller = useInstaller,
	useIsBusy = useIsBusy,
	useUpdates = useUpdates,
})
