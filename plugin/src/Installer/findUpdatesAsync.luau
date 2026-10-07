--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const SettingsStore = require(StudioDiscover.Source.SettingsStore)
const coreTypes = require(StudioDiscover.Libraries.Core.types)
const getRegistryMetadataAsync = require(StudioDiscover.Source.Api.getRegistryMetadataAsync)
const isRegistryEnabled = require(StudioDiscover.Source.Util.isRegistryEnabled)
const isUpdateCandidate = require(StudioDiscover.Libraries.Semver.isUpdateCandidate)
const types = require(StudioDiscover.Source.Installer.types)

--[[
	Fetches every root's metadata at once and yields until all of it is back. Each
		registry's HTTP client paces the requests. A root whose metadata failed to load
		is missing from the result.
]]
const function getAllMetadataAsync(roots: { coreTypes.InstalledRoot }): { [number]: coreTypes.PackageMetadata? }
	const results: { [number]: coreTypes.PackageMetadata? } = {}
	const thread = coroutine.running()
	local remaining = #roots
	local isWaiting = false

	for index, root in roots do
		task.spawn(function()
			results[index] = getRegistryMetadataAsync(root.registry, root.scope, root.name)
			remaining -= 1

			if remaining == 0 and isWaiting then
				task.spawn(thread)
			end
		end)
	end

	-- Cached metadata comes back without yielding, so every fetch may already be done.
	if remaining > 0 then
		isWaiting = true
		coroutine.yield()
	end

	return results
end

--[[
	Returns the roots that have a newer version on their registry, in the order given,
		and how many roots couldn't be checked because their metadata failed to load.
		Roots from a registry the user turned off are skipped.

	Each root is offered the newest version `isUpdateCandidate` allows, so a stable
		root never moves onto a prerelease.
]]
const function findUpdatesAsync(
	roots: { coreTypes.InstalledRoot },
	registries: SettingsStore.RegistryEnableMap
): ({ types.UpdateInfo }, number)
	const checked: { coreTypes.InstalledRoot } = {}
	for _, root in roots do
		if isRegistryEnabled(registries, root.registry) then
			table.insert(checked, root)
		end
	end

	const allMetadata = getAllMetadataAsync(checked)
	const updates: { types.UpdateInfo } = {}
	local failed = 0

	for index, root in checked do
		const metadata = allMetadata[index]
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
