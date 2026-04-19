--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local Charm = require(StudioDiscover.Packages.Charm)
local ReactCharm = require(StudioDiscover.Packages.ReactCharm)

local queryAtom = Charm.atom("")

local function useQuery(): string
	return ReactCharm.useAtom(queryAtom)
end

local function setQuery(value: string)
	queryAtom(value)
end

return table.freeze({
	useQuery = useQuery,
	setQuery = setQuery,
})
