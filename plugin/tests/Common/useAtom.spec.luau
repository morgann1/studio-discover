--!strict

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const ServerScriptService = game:GetService("ServerScriptService")

-- ReactRoblox only exports `act` under the mock scheduler, which it reads when it loads.
_G.__ROACT_17_MOCK_SCHEDULER__ = true

const JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
const describe = JestGlobals.describe
const expect = JestGlobals.expect
const test = JestGlobals.test

const StudioDiscover = ServerScriptService.StudioDiscover
const Charm = require(StudioDiscover.Packages.Charm)
const React = require(StudioDiscover.Packages.React)
const ReactRoblox = require(StudioDiscover.Packages.ReactRoblox)
const useAtom = require(StudioDiscover.Source.Common.useAtom)

const e = React.createElement

type Probe = {
	read container: Folder,
	read root: ReactRoblox.RootType,
	read renders: () -> number,
}

-- Mounts a TextLabel that shows the atom's value, and counts its renders.
const function mountProbe(atom: () -> number): Probe
	const container = Instance.new("Folder")
	const root = ReactRoblox.createRoot(container)
	local renders = 0

	const function Probe()
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

const function readText(probe: Probe): string?
	const label = probe.container:FindFirstChildOfClass("TextLabel")
	return if label ~= nil then label.Text else nil
end

describe("useAtom", function()
	test("renders the atom's current value", function()
		const probe = mountProbe(Charm.atom(1))

		expect(readText(probe)).toBe("1")
	end)

	test("re-renders when the atom changes", function()
		const atom = Charm.atom(1)
		const probe = mountProbe(atom)

		ReactRoblox.act(function()
			atom(2)
		end)

		expect(readText(probe)).toBe("2")
	end)

	test("re-renders when a selector's result changes", function()
		const atom = Charm.atom({ count = 1 })
		const probe = mountProbe(function()
			return atom().count
		end)

		ReactRoblox.act(function()
			atom({ count = 5 })
		end)

		expect(readText(probe)).toBe("5")
	end)

	test("stops rendering after unmount", function()
		const atom = Charm.atom(1)
		const probe = mountProbe(atom)

		ReactRoblox.act(function()
			probe.root:unmount()
		end)
		const rendersAtUnmount = probe.renders()

		ReactRoblox.act(function()
			atom(2)
		end)

		expect(probe.renders()).toBe(rendersAtUnmount)
	end)
end)
