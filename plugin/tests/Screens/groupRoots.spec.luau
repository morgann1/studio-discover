--!strict

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const ServerScriptService = game:GetService("ServerScriptService")

const JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
const describe = JestGlobals.describe
const expect = JestGlobals.expect
const test = JestGlobals.test

const StudioDiscover = ServerScriptService.StudioDiscover
const coreTypes = require(StudioDiscover.Libraries.Core.types)
const groupRoots = require(StudioDiscover.Source.Screens.InstalledScreen.groupRoots)
const installerTypes = require(StudioDiscover.Source.Installer.types)

const SETTINGS = {
	namingConvention = "Original",
	displayNames = {},
}

const function root(alias: string, realm: coreTypes.Realm, registry: coreTypes.Registry?): coreTypes.InstalledRoot
	return {
		scope = "someone",
		name = string.lower(alias),
		version = "1.0.0",
		realm = realm,
		alias = alias,
		registry = registry or "wally",
	}
end

const function updateFor(installed: coreTypes.InstalledRoot): installerTypes.UpdateInfo
	return {
		registry = installed.registry,
		scope = installed.scope,
		name = installed.name,
		realm = installed.realm,
		alias = installed.alias,
		installedVersion = installed.version,
		latestVersion = "2.0.0",
	}
end

const function aliases(group: groupRoots.Group): { string }
	const result: { string } = {}
	for _, entry in group.entries do
		table.insert(result, entry.root.alias)
	end

	return result
end

describe("groupRoots", function()
	test("groups by realm, shared first, sorted by alias", function()
		const groups = groupRoots(
			{ root("Signal", "shared"), root("Cmdr", "server"), root("Knit", "shared") },
			{},
			"",
			false,
			SETTINGS
		)

		expect(#groups).toBe(2)
		expect(groups[1].realm).toBe("shared")
		expect(aliases(groups[1])).toEqual({ "Knit", "Signal" })
		expect(aliases(groups[2])).toEqual({ "Cmdr" })
	end)

	test("pairs a root with its own update only, not one for the same package in another realm", function()
		const shared = root("Signal", "shared")
		const server = root("Signal", "server")
		const groups = groupRoots({ shared, server }, { updateFor(server) }, "", false, SETTINGS)

		expect(groups[1].entries[1].update).toBeNil()
		expect(groups[2].entries[1].update).never.toBeNil()
	end)

	test("keeps only roots with an update, and drops realms left empty", function()
		const outdated = root("Promise", "shared")
		const groups = groupRoots(
			{ root("Knit", "shared"), outdated, root("Cmdr", "server") },
			{ updateFor(outdated) },
			"",
			true,
			SETTINGS
		)

		expect(#groups).toBe(1)
		expect(aliases(groups[1])).toEqual({ "Promise" })
	end)

	test("names a Nevermore root by its package's name, and sorts and filters by it", function()
		const roots = { root("characterutils", "shared", "nevermore"), root("Knit", "shared") }
		const groups = groupRoots(roots, {}, "", false, SETTINGS)

		expect(groups[1].entries[1].displayName).toBe("CharacterUtils")
		expect(groups[1].entries[2].displayName).toBe("Knit")
		expect(#groupRoots(roots, {}, "CharacterU", false, SETTINGS)[1].entries).toBe(1)
	end)

	test("filters by alias, name, or scope, ignoring case", function()
		const roots = { root("Signal", "shared"), root("Knit", "shared") }

		expect(aliases(groupRoots(roots, {}, "SIG", false, SETTINGS)[1])).toEqual({ "Signal" })
		expect(#groupRoots(roots, {}, "someone", false, SETTINGS)[1].entries).toBe(2)
		expect(#groupRoots(roots, {}, "nothing", false, SETTINGS)).toBe(0)
	end)
end)
