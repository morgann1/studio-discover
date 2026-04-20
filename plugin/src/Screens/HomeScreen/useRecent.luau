--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local React = require(StudioDiscover.Packages.React)

local searchPesdeAsync = require(StudioDiscover.Source.Api.Pesde.searchAsync)
local types = require(StudioDiscover.Source.Api.types)

local LIMIT = 12

export type RecentState = {
	loading: boolean,
	packages: { types.PackageBrief },
	error: string?,
}

local EMPTY: RecentState = { loading = true, packages = {}, error = nil }

local function useRecent(): RecentState
	local state: RecentState, setState = React.useState(EMPTY)

	React.useEffect(function(): (() -> ())?
		local cancelled = false
		setState({ loading = true, packages = {}, error = nil })

		task.spawn(function()
			local results, err = searchPesdeAsync("")
			if cancelled then
				return
			end
			if results == nil then
				setState({ loading = false, packages = {}, error = err })
				return
			end

			local trimmed: { types.PackageBrief } = {}
			for _, pkg in results do
				if #trimmed >= LIMIT then
					break
				end
				table.insert(trimmed, pkg)
			end
			setState({ loading = false, packages = trimmed, error = nil })
		end)

		return function()
			cancelled = true
		end
	end, {})

	return state
end

return useRecent
