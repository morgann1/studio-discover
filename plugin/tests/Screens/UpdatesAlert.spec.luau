--!strict

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const ServerScriptService = game:GetService("ServerScriptService")

const JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
const describe = JestGlobals.describe
const expect = JestGlobals.expect
const test = JestGlobals.test

const StudioDiscover = ServerScriptService.StudioDiscover
const Foundation = require(StudioDiscover.Packages.Foundation)
const React = require(StudioDiscover.Packages.React)
const ReactRoblox = require(StudioDiscover.Packages.ReactRoblox)
const UpdatesAlert = require(StudioDiscover.Source.Screens.InstalledScreen.UpdatesAlert)
const installerTypes = require(StudioDiscover.Source.Installer.types)

const e = React.createElement

const PROMISE_UPDATE: installerTypes.UpdateInfo = {
	registry = "wally",
	scope = "evaera",
	name = "promise",
	realm = "shared",
	alias = "Promise",
	installedVersion = "3.2.0",
	latestVersion = "4.0.0",
}

-- Renders the alert after a finished check and returns every text it shows.
const function renderTexts(updates: { installerTypes.UpdateInfo }, failed: number): { [string]: true? }
	const container = Instance.new("ScreenGui")
	const root = ReactRoblox.createRoot(container)

	ReactRoblox.act(function()
		root:render(e(Foundation.FoundationProvider, {
			overlayGui = container,
		}, {
			Alert = e(UpdatesAlert, {
				updates = updates,
				failed = failed,
				isChecking = false,
			}),
		}))
	end)

	const texts: { [string]: true? } = {}
	for _, descendant in container:GetDescendants() do
		if descendant:IsA("TextLabel") or descendant:IsA("TextButton") then
			texts[descendant.Text] = true
		end
	end

	ReactRoblox.act(function()
		root:unmount()
	end)
	container:Destroy()

	return texts
end

describe("UpdatesAlert", function()
	test("says how many packages couldn't be checked alongside the updates it found", function()
		const texts = renderTexts({ PROMISE_UPDATE }, 2)

		expect(texts["1 update available. Couldn't check 2 packages."]).toBe(true)
		expect(texts["Update all"]).toBe(true)
		expect(texts["Try again"]).toBe(true)
	end)

	test("says a check failed when it found no updates", function()
		const texts = renderTexts({}, 3)

		expect(texts["Couldn't check 3 packages for updates."]).toBe(true)
		expect(texts["Try again"]).toBe(true)
	end)

	test("offers only Update all when every package was checked", function()
		const texts = renderTexts({ PROMISE_UPDATE }, 0)

		expect(texts["1 update available"]).toBe(true)
		expect(texts["Try again"]).toBeNil()
	end)
end)
