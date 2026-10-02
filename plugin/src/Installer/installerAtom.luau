--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const Charm = require(StudioDiscover.Packages.Charm)

const types = require(StudioDiscover.Source.Installer.types)

const INITIAL: types.InstallerState = {
	status = "idle",
	errors = {},
}

-- The latest install's progress and outcome, which the package screen shows.
const installerAtom = Charm.atom(INITIAL)

return installerAtom
