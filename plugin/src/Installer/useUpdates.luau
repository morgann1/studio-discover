--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local React = require(StudioDiscover.Packages.React)

local getPesdeMetadataAsync = require(StudioDiscover.Source.Api.Pesde.getMetadataAsync)
local getWallyMetadataAsync = require(StudioDiscover.Source.Api.Wally.getMetadataAsync)

local SettingsStore = require(StudioDiscover.Source.SettingsStore)
local compareSemver = require(StudioDiscover.Source.Util.compareSemver)
local parseSemver = require(StudioDiscover.Source.Util.parseSemver)

local installerTypes = require(StudioDiscover.Source.Installer.types)
local useInstalledRoots = require(StudioDiscover.Source.Installer.useInstalledRoots)

type Realm = installerTypes.Realm
type Registry = installerTypes.Registry

export type UpdateInfo = {
	scope: string,
	name: string,
	realm: Realm,
	alias: string,
	registry: Registry,
	installedVersion: string,
	latestVersion: string,
}

export type UpdatesState = {
	updates: { UpdateInfo },
	loading: boolean,
}

local EMPTY: UpdatesState = { updates = {}, loading = false }

local function useUpdates(): UpdatesState
	local installedState = useInstalledRoots()
	local installedRoots = installedState.roots
	local registries = SettingsStore.useSettings().registries
	local wallyEnabled = registries.wally
	local pesdeEnabled = registries.pesde
	local state: UpdatesState, setState = React.useState(EMPTY)

	React.useEffect(function(): (() -> ())?
		if installedState.loading then
			setState({ updates = {}, loading = true })
			return nil
		end
		if #installedRoots == 0 then
			setState(EMPTY)
			return nil
		end

		local cancelled = false
		setState({ updates = {}, loading = true })

		task.spawn(function()
			local updates: { UpdateInfo } = {}
			for _, root in installedRoots do
				if cancelled then
					return
				end
				if root.registry == "wally" and not wallyEnabled then
					continue
				end
				if root.registry == "pesde" and not pesdeEnabled then
					continue
				end
				local metadata = if root.registry == "pesde"
					then getPesdeMetadataAsync(root.scope, root.name)
					else getWallyMetadataAsync(root.scope, root.name)
				if metadata == nil or metadata.versions == nil or #metadata.versions == 0 then
					continue
				end
				local latest = metadata.versions[1].package.version
				local latestSv = parseSemver(latest)
				local installedSv = parseSemver(root.version)
				if latestSv == nil or installedSv == nil then
					continue
				end
				if compareSemver(latestSv, installedSv) > 0 then
					table.insert(updates, {
						scope = root.scope,
						name = root.name,
						realm = root.realm,
						alias = root.alias,
						registry = root.registry,
						installedVersion = root.version,
						latestVersion = latest,
					})
				end
			end
			if cancelled then
				return
			end
			setState({ updates = updates, loading = false })
		end)

		return function()
			cancelled = true
		end
	end, { installedRoots, wallyEnabled, pesdeEnabled } :: { any })

	return state
end

return useUpdates
