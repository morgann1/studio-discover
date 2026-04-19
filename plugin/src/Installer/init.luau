--!strict

local installAsync = require(script.installAsync)
local useInstaller = require(script.useInstaller)

return table.freeze({
	installAsync = installAsync,
	useInstaller = useInstaller,
})
