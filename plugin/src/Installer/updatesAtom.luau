--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const Charm = require(StudioDiscover.Packages.Charm)

const SettingsStore = require(StudioDiscover.Source.SettingsStore)
const findUpdatesAsync = require(StudioDiscover.Source.Installer.findUpdatesAsync)
const installedRootsAtom = require(StudioDiscover.Source.Installer.installedRootsAtom)
const types = require(StudioDiscover.Source.Installer.types)

-- `failed` counts the roots the last check couldn't reach their registry for.
export type UpdatesState = {
	read updates: { types.UpdateInfo },
	read failed: number,
	read loading: boolean,
}

-- The installed roots with a newer version, checked once and shared by every screen.
const updatesAtom = Charm.atom<<UpdatesState>>({ updates = {}, failed = 0, loading = true })

-- Only the registry switches, so changing an unrelated setting doesn't check again.
const registriesAtom = Charm.computed(function()
	return SettingsStore.getSettings().registries
end)

--[[
	Checks again whenever the installed roots or the enabled registries change. The
		previous updates stay listed while the check runs, so the list doesn't blink
		empty after every install.
]]
Charm.effect(function()
	const roots = installedRootsAtom()
	const registries = registriesAtom()
	local cancelled = false

	if roots ~= nil then
		updatesAtom(function(previous)
			return { updates = previous.updates, failed = previous.failed, loading = true }
		end)

		task.spawn(function()
			const updates, failed = findUpdatesAsync(roots, registries)
			if not cancelled then
				updatesAtom({ updates = updates, failed = failed, loading = false })
			end
		end)
	end

	return function()
		cancelled = true
	end
end)

return updatesAtom
