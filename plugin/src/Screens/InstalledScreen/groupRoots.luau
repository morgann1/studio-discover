--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const coreTypes = require(StudioDiscover.Libraries.Core.types)
const installerTypes = require(StudioDiscover.Source.Installer.types)
const realms = require(StudioDiscover.Libraries.Core.realms)

-- One installed root, with its update when it has one.
export type Entry = {
	read root: coreTypes.InstalledRoot,
	read update: installerTypes.UpdateInfo?,
}

export type Group = {
	read realm: coreTypes.Realm,
	read entries: { Entry },
}

const function matches(root: coreTypes.InstalledRoot, query: string): boolean
	const needle = string.lower(query)

	for _, text in { root.alias, root.name, root.scope } do
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
	Pairs each root with its update and groups them by realm, sorted by alias. Keeps
		only the roots matching `query` by alias, name, or scope, and with
		`onlyUpdates`, only the ones with an update. Realms left empty are dropped.
]]
const function groupRoots(
	roots: { coreTypes.InstalledRoot },
	updates: { installerTypes.UpdateInfo },
	query: string,
	onlyUpdates: boolean
): { Group }
	const groups: { Group } = {}

	for _, realm in realms do
		const entries: { Entry } = {}

		for _, root in roots do
			const update = findUpdate(updates, root)

			if root.realm ~= realm or (onlyUpdates and update == nil) or not matches(root, query) then
				continue
			end

			table.insert(entries, { root = root, update = update })
		end

		table.sort(entries, function(a, b)
			return string.lower(a.root.alias) < string.lower(b.root.alias)
		end)

		if #entries > 0 then
			table.insert(groups, { realm = realm, entries = entries })
		end
	end

	return groups
end

return groupRoots
