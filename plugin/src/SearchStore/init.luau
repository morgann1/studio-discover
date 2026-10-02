--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local Charm = require(StudioDiscover.Packages.Charm)
local useAtom = require(StudioDiscover.Source.Common.useAtom)

local queryAtom = Charm.atom("")

local function useQuery(): string
	return useAtom(queryAtom)
end

local function setQuery(value: string)
	queryAtom(value)
end

return table.freeze({
	useQuery = useQuery,
	setQuery = setQuery,
})
