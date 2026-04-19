--!strict

local installAsync = require(script.installAsync)
local useInstalledRoots = require(script.useInstalledRoots)
local useInstaller = require(script.useInstaller)

return table.freeze({
	installAsync = installAsync,
	useInstalledRoots = useInstalledRoots,
	useInstaller = useInstaller,
})
