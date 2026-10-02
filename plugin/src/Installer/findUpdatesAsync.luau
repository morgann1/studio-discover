--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const getPesdeMetadataAsync = require(StudioDiscover.Libraries.PesdeRegistry.Api.getMetadataAsync)
const getWallyMetadataAsync = require(StudioDiscover.Libraries.WallyRegistry.Api.getMetadataAsync)

const SettingsStore = require(StudioDiscover.Source.SettingsStore)
const coreTypes = require(StudioDiscover.Libraries.Core.types)
const isNewerVersion = require(StudioDiscover.Libraries.Semver.isNewerVersion)
const types = require(StudioDiscover.Source.Installer.types)

--[[
	Returns the roots that have a newer version on their registry, asking each
		registry in turn. Roots from a registry the user turned off are skipped, and so
		is any root whose metadata fails to load.
]]
const function findUpdatesAsync(
	roots: { coreTypes.InstalledRoot },
	registries: SettingsStore.RegistryEnableMap
): { types.UpdateInfo }
	const updates: { types.UpdateInfo } = {}

	for _, root in roots do
		const enabled = if root.registry == "pesde" then registries.pesde else registries.wally
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
		if isNewerVersion(latest, root.version) then
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

	return updates
end

return findUpdatesAsync
