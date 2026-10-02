--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const React = require(StudioDiscover.Packages.React)

const getPesdeMetadataAsync = require(StudioDiscover.Libraries.PesdeRegistry.Api.getMetadataAsync)
const getWallyMetadataAsync = require(StudioDiscover.Libraries.WallyRegistry.Api.getMetadataAsync)

const compareSemver = require(StudioDiscover.Libraries.Semver.compareSemver)
const parseSemver = require(StudioDiscover.Libraries.Semver.parseSemver)

const SettingsStore = require(StudioDiscover.Source.SettingsStore)
const types = require(StudioDiscover.Source.Installer.types)
const useInstalledRoots = require(StudioDiscover.Source.Installer.useInstalledRoots)

export type UpdatesState = {
	read updates: { types.UpdateInfo },
	read loading: boolean,
}

const IDLE: UpdatesState = { updates = {}, loading = false }
const LOADING: UpdatesState = { updates = {}, loading = true }

--[[
	Returns the installed roots that have a newer version on their registry. Roots
		from a registry the user turned off are skipped.
]]
const function useUpdates(): UpdatesState
	const installedState = useInstalledRoots()
	const installedRoots = installedState.roots
	const registries = SettingsStore.useSettings().registries
	const wallyEnabled = registries.wally
	const pesdeEnabled = registries.pesde
	const state, setState = React.useState(IDLE)

	React.useEffect(function()
		local cancelled = false

		if installedState.loading or #installedRoots == 0 then
			setState(if installedState.loading then LOADING else IDLE)

			return function()
				cancelled = true
			end
		end

		setState(LOADING)

		task.spawn(function()
			const updates: { types.UpdateInfo } = {}

			for _, root in installedRoots do
				if cancelled then
					return
				end

				const enabled = if root.registry == "pesde" then pesdeEnabled else wallyEnabled
				if not enabled then
					continue
				end

				const metadata = if root.registry == "pesde"
					then getPesdeMetadataAsync(root.scope, root.name)
					else getWallyMetadataAsync(root.scope, root.name)
				if metadata == nil or #metadata.versions == 0 then
					continue
				end

				const latest = metadata.versions[1].package.version
				const latestSemver = parseSemver(latest)
				const installedSemver = parseSemver(root.version)
				if latestSemver == nil or installedSemver == nil then
					continue
				end

				if compareSemver(latestSemver, installedSemver) > 0 then
					table.insert(updates, {
						registry = root.registry,
						scope = root.scope,
						name = root.name,
						realm = root.realm,
						alias = root.alias,
						installedVersion = root.version,
						latestVersion = latest,
					})
				end
			end

			if not cancelled then
				setState({ updates = updates, loading = false })
			end
		end)

		return function()
			cancelled = true
		end
	end, { installedState.loading, installedRoots, wallyEnabled, pesdeEnabled } :: { unknown })

	return state
end

return useUpdates
