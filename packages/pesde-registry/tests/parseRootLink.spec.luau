--!strict

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const ServerScriptService = game:GetService("ServerScriptService")

const JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
const describe = JestGlobals.describe
const expect = JestGlobals.expect
const it = JestGlobals.it

const PesdeRegistry = ServerScriptService.StudioDiscover.Libraries.PesdeRegistry
const buildPackageLink = require(PesdeRegistry.buildPackageLink)
const parseRootLink = require(PesdeRegistry.parseRootLink)

describe("parseRootLink", function()
	--[[
		Installed roots are read back out of the links apply wrote, so whatever
			`buildTopLevelLink` writes has to parse back to the same package.
	]]
	it("reads back the package a root link was built for", function()
		const build = buildPackageLink.buildTopLevelLink("Signal", {
			packageId = "molyidev/signal@1.0.3 roblox",
			scope = "molyidev",
			name = "signal",
			version = "1.0.3",
			realm = "shared",
			libPath = "src/init.luau",
			dependencies = {},
		}, { "export type Signal<T...> = module.Signal<T...>" })

		expect(parseRootLink(build.source)).toEqual({ scope = "molyidev", name = "signal", version = "1.0.3" })
	end)

	it("rejects a module that only mentions the index further down", function()
		const source =
			'local cache = {}\nlocal module = require("./.pesde/molyidev+signal/1.0.3/signal")\nreturn module'

		expect(parseRootLink(source)).toBeNil()
	end)
end)
