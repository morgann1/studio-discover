--!strict

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const ServerScriptService = game:GetService("ServerScriptService")

const JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
const describe = JestGlobals.describe
const expect = JestGlobals.expect
const it = JestGlobals.it
const jest = JestGlobals.jest

const StudioDiscover = ServerScriptService.StudioDiscover

-- What both registries publish in the current test, newest first, as their metadata readers sort it.
local published: { string } = {}

const function getMetadataAsync()
	const versions = {}
	for _, version in published do
		table.insert(versions, { package = { version = version } })
	end

	return { versions = versions }
end

jest.mock(StudioDiscover.Libraries.WallyRegistry.Api.getMetadataAsync, function()
	return getMetadataAsync
end)
jest.mock(StudioDiscover.Libraries.PesdeRegistry.Api.getMetadataAsync, function()
	return getMetadataAsync
end)

const coreTypes = require(StudioDiscover.Libraries.Core.types)
const findUpdatesAsync = require(StudioDiscover.Source.Installer.findUpdatesAsync)

const function root(registry: coreTypes.Registry, version: string): coreTypes.InstalledRoot
	return { registry = registry, scope = "scope", name = "name", version = version, realm = "shared", alias = "Name" }
end

-- The version each root is offered, or "none".
const function offered(roots: { coreTypes.InstalledRoot }): { string }
	const updates = findUpdatesAsync(roots, { wally = true, pesde = true })

	const versions = {}
	for _, installed in roots do
		local latest = "none"
		for _, update in updates do
			if update.registry == installed.registry and update.installedVersion == installed.version then
				latest = update.latestVersion
			end
		end
		table.insert(versions, latest)
	end

	return versions
end

describe("findUpdatesAsync", function()
	it("offers a stable root the newest release, not a newer prerelease", function()
		published = { "2.0.0-rc.1", "1.5.0", "1.0.0" }

		expect(offered({ root("wally", "1.0.0"), root("pesde", "1.0.0") })).toEqual({ "1.5.0", "1.5.0" })
	end)

	it("offers a prerelease root a newer prerelease of its own version, not of a later one", function()
		published = { "0.7.0-rc.1", "0.6.0-rc.6", "0.6.0-rc.1" }

		expect(offered({ root("wally", "0.6.0-rc.1"), root("pesde", "0.6.0-rc.1") })).toEqual({
			"0.6.0-rc.6",
			"0.6.0-rc.6",
		})
	end)
end)
