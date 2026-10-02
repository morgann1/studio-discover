--!strict

const installAsync = require(script.installAsync)
const uninstallAsync = require(script.uninstallAsync)
const updateAllAsync = require(script.updateAllAsync)
const useInstalledRoots = require(script.useInstalledRoots)
const useInstaller = require(script.useInstaller)
const useIsBusy = require(script.useIsBusy)
const useUpdates = require(script.useUpdates)

const Installer = table.freeze({
	installAsync = installAsync,
	uninstallAsync = uninstallAsync,
	updateAllAsync = updateAllAsync,
	useInstalledRoots = useInstalledRoots,
	useInstaller = useInstaller,
	useIsBusy = useIsBusy,
	useUpdates = useUpdates,
})

return Installer
