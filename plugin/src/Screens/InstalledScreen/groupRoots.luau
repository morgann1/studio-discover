--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const coreTypes = require(StudioDiscover.Libraries.Core.types)
const installerTypes = require(StudioDiscover.Source.Installer.types)
const packageDisplayName = require(StudioDiscover.Source.Util.packageDisplayName)
const realms = require(StudioDiscover.Libraries.Core.realms)
const rootDisplayName = require(StudioDiscover.Source.Util.rootDisplayName)

-- One installed root, the name it goes by, and its update when it has one.
export type Entry = {
	read root: coreTypes.InstalledRoot,
	read displayName: string,
	read update: installerTypes.UpdateInfo?,
}

export type Group = {
	read realm: coreTypes.Realm,
	read entries: { Entry },
}

const function matches(root: coreTypes.InstalledRoot, displayName: string, query: string): boolean
	const needle = string.lower(query)

	for _, text in { displayName, root.alias, root.name, root.scope } do
		if string.find(string.lower(text), needle, 1, true) ~= nil then
			return true
		end
	end

	return false
end

const function findUpdate(
	updates: { installerTypes.UpdateInfo },
	root: coreTypes.InstalledRoot
): installerTypes.UpdateInfo?
	for _, update in updates do
		if
			update.registry == root.registry
			and update.realm == root.realm
			and update.scope == root.scope
			and update.name == root.name
		then
			return update
		end
	end

	return nil
end

--[[
	Pairs each root with its name and update and groups them by realm, sorted by
		name. Keeps only the roots matching `query` by name, alias, package name, or
		scope, and with `onlyUpdates`, only the ones with an update. Realms left empty
		are dropped.
]]
const function groupRoots(
	roots: { coreTypes.InstalledRoot },
	updates: { installerTypes.UpdateInfo },
	query: string,
	onlyUpdates: boolean,
	settings: packageDisplayName.NameSettings
): { Group }
	const groups: { Group } = {}

	for _, realm in realms do
		const entries: { Entry } = {}

		for _, root in roots do
			const update = findUpdate(updates, root)
			const displayName = rootDisplayName(root, settings)

			if root.realm ~= realm or (onlyUpdates and update == nil) or not matches(root, displayName, query) then
				continue
			end

			table.insert(entries, { root = root, displayName = displayName, update = update })
		end

		table.sort(entries, function(a, b)
			return string.lower(a.displayName) < string.lower(b.displayName)
		end)

		if #entries > 0 then
			table.insert(groups, { realm = realm, entries = entries })
		end
	end

	return groups
end

return groupRoots
