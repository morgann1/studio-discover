--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local React = require(StudioDiscover.Packages.React)

local getPackageMetadataAsync = require(StudioDiscover.Source.Api.getPackageMetadataAsync)
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

-- Fires on (scope, name) change. Superseded responses are discarded via a
-- cancelled flag; the in-flight request finishes so its result lands in the
-- URL cache for the next navigation.
local function usePackageMetadata(scope: string, name: string): MetadataState
	local state: MetadataState, setState = React.useState(EMPTY)

	React.useEffect(function(): (() -> ())?
		if scope == "" or name == "" then
			setState(EMPTY)
			return nil
		end

		local cancelled = false
		setState({ loading = true, data = nil, error = nil })

		task.spawn(function()
			local data, err = getPackageMetadataAsync(scope, name)
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
	end, { scope, name })

	return state
end

return usePackageMetadata
