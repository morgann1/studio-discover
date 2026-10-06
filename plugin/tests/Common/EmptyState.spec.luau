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
const EmptyState = require(StudioDiscover.Source.Common.EmptyState)
const iconName = require(StudioDiscover.Source.Util.iconName)

const e = React.createElement

--[[
	Renders an empty state with a Browse action and returns every text it shows.
		Foundation draws icons as glyph names in text, so icons show up here too.
]]
const function renderTexts(): { [string]: true? }
	const container = Instance.new("ScreenGui")
	const root = ReactRoblox.createRoot(container)

	ReactRoblox.act(function()
		root:render(e(Foundation.FoundationProvider, {
			overlayGui = container,
		}, {
			EmptyState = e(EmptyState, {
				icon = iconName("FileBox"),
				text = "Nothing is installed in this place yet.",
				action = {
					text = "Browse Wally",
					icon = iconName("MagnifyingGlass"),
					onActivated = function() end,
				},
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

describe("EmptyState", function()
	test("shows the action's icon on its button instead of Foundation's Refresh icon", function()
		const texts = renderTexts()

		expect(texts["Browse Wally"]).toBe(true)
		expect(texts[iconName("MagnifyingGlass")]).toBe(true)
		expect(texts[iconName("TwoArrowsSpinClockwise")]).toBeNil()
	end)
end)
