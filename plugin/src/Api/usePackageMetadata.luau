--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local React = require(StudioDiscover.Packages.React)

local getPackageMetadataAsync = require(StudioDiscover.Source.Api.Wally.getMetadataAsync)
local getPesdeMetadataAsync = require(StudioDiscover.Source.Api.Pesde.getMetadataAsync)
local types = require(StudioDiscover.Source.Api.types)

export type MetadataState = {
	loading: boolean,
	data: types.WallyPackageMetadata?,
	error: string?,
}

local EMPTY: MetadataState = table.freeze({
	loading = false,
	data = nil,
	error = nil,
})

-- Registries share a normalized Wally-shaped result so the Package screen
-- doesn't need to branch per source.
local function fetchAsync(registry: types.Registry, scope: string, name: string): (types.WallyPackageMetadata?, string?)
	if registry == "pesde" then
		return getPesdeMetadataAsync(scope, name)
	end
	return getPackageMetadataAsync(scope, name)
end

local function usePackageMetadata(scope: string, name: string, registry: types.Registry?): MetadataState
	local resolvedRegistry: types.Registry = registry or "wally"
	local state: MetadataState, setState = React.useState(EMPTY)

	React.useEffect(function(): (() -> ())?
		if scope == "" or name == "" then
			setState(EMPTY)
			return nil
		end

		local cancelled = false
		setState({ loading = true, data = nil, error = nil })

		task.spawn(function()
			local data, err = fetchAsync(resolvedRegistry, scope, name)
			if cancelled then
				return
			end
			setState({
				loading = false,
				data = data,
				error = err,
			})
		end)

		return function()
			cancelled = true
		end
	end, { scope, name, resolvedRegistry } :: { any })

	return state
end

return usePackageMetadata
