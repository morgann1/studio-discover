--!strict

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const ServerScriptService = game:GetService("ServerScriptService")

const JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
const describe = JestGlobals.describe
const expect = JestGlobals.expect
const test = JestGlobals.test

const StudioDiscover = ServerScriptService.StudioDiscover
const Navigation = require(StudioDiscover.Source.Navigation)
const SearchStore = require(StudioDiscover.Source.SearchStore)
const pickLocation = require(StudioDiscover.Source.Common.Locations.pickLocation)

describe("pickLocation", function()
	test("clears the search query when leaving a search", function()
		SearchStore.setQuery("promise")
		Navigation.resetScreen({ name = "Search" })

		pickLocation({ name = "Installed" })

		expect(Navigation.getRoute().name).toBe("Installed")
		expect(SearchStore.getQuery()).toBe("")
	end)
end)
