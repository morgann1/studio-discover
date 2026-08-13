--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local React = require(StudioDiscover.Packages.React)

local getPackageMetadataAsync = require(StudioDiscover.WallyRegistry.Api.getMetadataAsync)
local getPesdeMetadataAsync = require(StudioDiscover.PesdeRegistry.Api.getMetadataAsync)
local coreTypes = require(StudioDiscover.Core.types)

export type MetadataState = {
	loading: boolean,
	data: coreTypes.PackageMetadata?,
	error: string?,
}

local EMPTY: MetadataState = table.freeze({
	loading = false,
	data = nil,
	error = nil,
})

local function fetchAsync(
	registry: coreTypes.Registry,
	scope: string,
	name: string
): (coreTypes.PackageMetadata?, string?)
	if registry == "pesde" then
		return getPesdeMetadataAsync(scope, name)
	end
	return getPackageMetadataAsync(scope, name)
end

local function usePackageMetadata(scope: string, name: string, registry: coreTypes.Registry?): MetadataState
	local resolvedRegistry: coreTypes.Registry = registry or "wally"
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
