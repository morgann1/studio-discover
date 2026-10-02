--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- ReactRoblox only exports `act` under the mock scheduler, which it reads when it loads.
_G.__ROACT_17_MOCK_SCHEDULER__ = true

local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
local describe = JestGlobals.describe
local expect = JestGlobals.expect
local test = JestGlobals.test

local StudioDiscover = ServerScriptService:WaitForChild("StudioDiscover") :: Folder
local Charm = require(StudioDiscover.Packages.Charm)
local React = require(StudioDiscover.Packages.React)
local ReactRoblox = require(StudioDiscover.Packages.ReactRoblox)
local useAtom = require(StudioDiscover.Source.Common.useAtom)

local e = React.createElement

type Probe = {
	read container: Folder,
	read root: ReactRoblox.RootType,
	read renders: () -> number,
}

-- Mounts a TextLabel that shows the atom's value, and counts its renders.
local function mountProbe(atom: () -> number): Probe
	local container = Instance.new("Folder")
	local root = ReactRoblox.createRoot(container)
	local renders = 0

	local function Probe()
		renders += 1
		return e("TextLabel", { Text = tostring(useAtom(atom)) })
	end

	ReactRoblox.act(function()
		root:render(e(Probe))
	end)

	return {
		container = container,
		root = root,
		renders = function()
			return renders
		end,
	}
end

local function readText(probe: Probe): string?
	local label = probe.container:FindFirstChildOfClass("TextLabel")
	return if label ~= nil then label.Text else nil
end

describe("useAtom", function()
	test("renders the atom's current value", function()
		local probe = mountProbe(Charm.atom(1))

		expect(readText(probe)).toBe("1")
	end)

	test("re-renders when the atom changes", function()
		local atom = Charm.atom(1)
		local probe = mountProbe(atom)

		ReactRoblox.act(function()
			atom(2)
		end)

		expect(readText(probe)).toBe("2")
	end)

	test("re-renders when a selector's result changes", function()
		local atom = Charm.atom({ count = 1 })
		local probe = mountProbe(function()
			return atom().count
		end)

		ReactRoblox.act(function()
			atom({ count = 5 })
		end)

		expect(readText(probe)).toBe("5")
	end)

	test("stops rendering after unmount", function()
		local atom = Charm.atom(1)
		local probe = mountProbe(atom)

		ReactRoblox.act(function()
			probe.root:unmount()
		end)
		local rendersAtUnmount = probe.renders()

		ReactRoblox.act(function()
			atom(2)
		end)

		expect(probe.renders()).toBe(rendersAtUnmount)
	end)
end)
