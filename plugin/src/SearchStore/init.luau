--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const Charm = require(StudioDiscover.Packages.Charm)

const useAtom = require(StudioDiscover.Source.Common.useAtom)

-- The search across every source, typed in the sidebar and shown by the Search screen.
const queryAtom = Charm.atom("")

const function useQuery(): string
	return useAtom(function()
		return queryAtom()
	end)
end

const function getQuery(): string
	return queryAtom()
end

const function setQuery(value: string)
	queryAtom(value)
end

const SearchStore = table.freeze({
	useQuery = useQuery,
	getQuery = getQuery,
	setQuery = setQuery,
})

return SearchStore
