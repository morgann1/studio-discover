--!strict

local installAsync = require(script.installAsync)
local uninstallAsync = require(script.uninstallAsync)
local useInstalledRoots = require(script.useInstalledRoots)
local useInstaller = require(script.useInstaller)

return table.freeze({
	installAsync = installAsync,
	uninstallAsync = uninstallAsync,
	useInstalledRoots = useInstalledRoots,
	useInstaller = useInstaller,
})
