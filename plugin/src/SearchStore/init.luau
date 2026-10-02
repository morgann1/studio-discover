--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const Charm = require(StudioDiscover.Packages.Charm)

const useAtom = require(StudioDiscover.Source.Common.useAtom)

-- The sidebar's search text, which Home reads to show results.
const queryAtom = Charm.atom("")

const function useQuery(): string
	return useAtom(function()
		return queryAtom()
	end)
end

const function setQuery(value: string)
	queryAtom(value)
end

const SearchStore = table.freeze({
	useQuery = useQuery,
	setQuery = setQuery,
})

return SearchStore
