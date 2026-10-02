--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const React = require(StudioDiscover.Packages.React)

const coreTypes = require(StudioDiscover.Libraries.Core.types)
const getPesdeMetadataAsync = require(StudioDiscover.Libraries.PesdeRegistry.Api.getMetadataAsync)
const getWallyMetadataAsync = require(StudioDiscover.Libraries.WallyRegistry.Api.getMetadataAsync)

export type MetadataState = {
	read loading: boolean,
	read data: coreTypes.PackageMetadata?,
	read error: string?,
}

const IDLE: MetadataState = { loading = false }
const LOADING: MetadataState = { loading = true }

const function fetchAsync(
	registry: coreTypes.Registry,
	scope: string,
	name: string
): (coreTypes.PackageMetadata?, string?)
	if registry == "pesde" then
		return getPesdeMetadataAsync(scope, name)
	end

	return getWallyMetadataAsync(scope, name)
end

-- Fetches a package's metadata from one registry, again whenever the package or registry changes.
const function usePackageMetadata(registry: coreTypes.Registry, scope: string, name: string): MetadataState
	const state, setState = React.useState(IDLE)

	React.useEffect(function()
		local cancelled = false

		if scope == "" or name == "" then
			setState(IDLE)
		else
			setState(LOADING)

			task.spawn(function()
				const data, err = fetchAsync(registry, scope, name)
				if not cancelled then
					setState({ loading = false, data = data, error = err })
				end
			end)
		end

		return function()
			cancelled = true
		end
	end, { registry, scope, name })

	return state
end

return usePackageMetadata
