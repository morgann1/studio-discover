--!strict

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const ServerScriptService = game:GetService("ServerScriptService")

const JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
const describe = JestGlobals.describe
const expect = JestGlobals.expect
const it = JestGlobals.it
const jest = JestGlobals.jest

const NevermoreRegistry = ServerScriptService.StudioDiscover.Libraries.NevermoreRegistry

-- Each package's versions and its `latest` tag, as npm lists them.
const PACKAGES = {
	["@quenty/maid"] = {
		latest = "3.12.1",
		versions = { "3.8.1-canary.684.24818543952.0", "3.12.0", "3.12.1" },
	},
	["@quentystudios/cmdr"] = {
		latest = "1.12.0-quenty.0",
		versions = { "1.11.0-quenty.0", "1.12.0-quenty.0" },
	},
}

jest.mock(NevermoreRegistry.Api.fetchPackumentAsync, function()
	return function(name: string)
		const package = PACKAGES[name]
		if package == nil then
			return nil, "not found", true
		end

		const versions = {}
		for _, version in package.versions do
			table.insert(versions, { version = version, dependencies = { ["@quenty/loader"] = "10.11.2" } })
		end

		return { versions = versions, latest = package.latest }, nil, false
	end
end)

jest.mock(NevermoreRegistry.Api.fetchVersionAsync, function()
	return function(_name: string, version: string)
		return {
			version = version,
			dependencies = {},
			description = "Cleans up",
			license = "MIT",
			authors = { "Quenty" },
		},
			nil,
			false
	end
end)

const getMetadataAsync = require(NevermoreRegistry.Api.getMetadataAsync)

const function versionsOf(scope: string, name: string): { string }
	const metadata = getMetadataAsync(scope, name)
	assert(metadata ~= nil, "expected metadata")

	const versions = {}
	for _, entry in metadata.versions do
		table.insert(versions, entry.package.version)
	end

	return versions
end

describe("getMetadataAsync", function()
	it("lists releases newest first and leaves the canary builds out", function()
		expect(versionsOf("quenty", "maid")).toEqual({ "3.12.1", "3.12.0" })
	end)

	it("lists prereleases when the latest version is one", function()
		expect(versionsOf("quentystudios", "cmdr")).toEqual({ "1.12.0-quenty.0", "1.11.0-quenty.0" })
	end)

	it("writes dependencies as scope/name@range for the package screen", function()
		const metadata = getMetadataAsync("quenty", "maid")
		assert(metadata ~= nil, "expected metadata")

		expect(metadata.versions[1].dependencies).toEqual({ ["@quenty/loader"] = "quenty/loader@10.11.2" })
	end)

	it("returns no versions for a package npm doesn't have", function()
		expect(getMetadataAsync("quenty", "missing")).toEqual({ versions = {} })
	end)
end)
