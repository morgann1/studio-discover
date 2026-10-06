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

-- How long each package's metadata takes to arrive in the current test, by name.
local delays: { [string]: number } = {}

local inFlight = 0
local mostInFlight = 0

const function getMetadataAsync(_scope: string, name: string)
	inFlight += 1
	mostInFlight = math.max(mostInFlight, inFlight)

	const delay = delays[name]
	if delay ~= nil then
		task.wait(delay)
	end
	inFlight -= 1

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

const function root(registry: coreTypes.Registry, version: string, name: string?): coreTypes.InstalledRoot
	return {
		registry = registry,
		scope = "scope",
		name = name or "name",
		version = version,
		realm = "shared",
		alias = "Name",
	}
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

	it("checks every root at once and keeps the roots' order", function()
		published = { "2.0.0", "1.0.0" }
		delays = { slow = 0.2, fast = 0 }
		mostInFlight = 0

		const updates = findUpdatesAsync(
			{ root("wally", "1.0.0", "slow"), root("pesde", "1.0.0", "fast") },
			{ wally = true, pesde = true }
		)

		expect(mostInFlight).toBe(2)
		expect(#updates).toBe(2)
		expect(updates[1].name).toBe("slow")
		expect(updates[2].name).toBe("fast")
	end)
end)
