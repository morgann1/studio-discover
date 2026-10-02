--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const Installer = require(StudioDiscover.Source.Installer)
const coreTypes = require(StudioDiscover.Libraries.Core.types)

export type PackageStatus = "installed" | "update"

const function keyOf(registry: coreTypes.Registry, scope: string, name: string): string
	return `{registry}:{string.lower(scope)}/{string.lower(name)}`
end

--[[
	Returns a lookup for whether a package is installed in this place, and whether it
		has an update, so a listing can mark its rows.
]]
const function usePackageStatus(): (registry: coreTypes.Registry, scope: string, name: string) -> PackageStatus?
	const roots = Installer.useInstalledRoots().roots
	const updates = Installer.useUpdates().updates

	const statuses: { [string]: PackageStatus? } = {}
	for _, root in roots do
		statuses[keyOf(root.registry, root.scope, root.name)] = "installed"
	end

	for _, update in updates do
		statuses[keyOf(update.registry, update.scope, update.name)] = "update"
	end

	return function(registry, scope, name)
		return statuses[keyOf(registry, scope, name)]
	end
end

return usePackageStatus
