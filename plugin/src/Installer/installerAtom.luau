--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local Charm = require(StudioDiscover.Packages.Charm)

local types = require(StudioDiscover.Source.Installer.types)

type InstallerState = types.InstallerState

local INITIAL: InstallerState = table.freeze({
	status = "idle" :: "idle",
	message = nil,
	errors = table.freeze({}),
})

local installerAtom = Charm.atom(INITIAL :: InstallerState)

return installerAtom
