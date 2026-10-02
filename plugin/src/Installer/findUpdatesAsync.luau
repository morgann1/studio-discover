--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const getPesdeMetadataAsync = require(StudioDiscover.Libraries.PesdeRegistry.Api.getMetadataAsync)
const getWallyMetadataAsync = require(StudioDiscover.Libraries.WallyRegistry.Api.getMetadataAsync)

const SettingsStore = require(StudioDiscover.Source.SettingsStore)
const coreTypes = require(StudioDiscover.Libraries.Core.types)
const isUpdateCandidate = require(StudioDiscover.Libraries.Semver.isUpdateCandidate)
const types = require(StudioDiscover.Source.Installer.types)

--[[
	Returns the roots that have a newer version on their registry, asking each
		registry in turn, and how many roots couldn't be checked because their metadata
		failed to load. Roots from a registry the user turned off are skipped.

	Each root is offered the newest version `isUpdateCandidate` allows, so a stable
		root never moves onto a prerelease.
]]
const function findUpdatesAsync(
	roots: { coreTypes.InstalledRoot },
	registries: SettingsStore.RegistryEnableMap
): ({ types.UpdateInfo }, number)
	const updates: { types.UpdateInfo } = {}
	local failed = 0

	for _, root in roots do
		const enabled = if root.registry == "pesde" then registries.pesde else registries.wally
		if not enabled then
			continue
		end

		const metadata = if root.registry == "pesde"
			then getPesdeMetadataAsync(root.scope, root.name)
			else getWallyMetadataAsync(root.scope, root.name)
		if metadata == nil then
			failed += 1
			continue
		end

		-- Versions come newest first, so the first candidate is the newest one.
		for _, versionData in metadata.versions do
			const latest = versionData.package.version
			if not isUpdateCandidate(root.version, latest) then
				continue
			end

			table.insert(updates, {
				registry = root.registry,
				scope = root.scope,
				name = root.name,
				realm = root.realm,
				alias = root.alias,
				installedVersion = root.version,
				latestVersion = latest,
			})
			break
		end
	end

	return updates, failed
end

return findUpdatesAsync
