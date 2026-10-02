--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const types = require(StudioDiscover.Libraries.Core.types)

--[[
	A registry's square mark. `crop` picks the mark out of a larger image, for marks
		that only exist inside a wordmark so far. Places that can't crop, such as the
		breadcrumb, skip a cropped mark.
]]
export type Mark = {
	read image: string,
	read crop: Rect?,
}

const MARKS: { [types.Registry]: Mark } = {
	-- The walrus, cropped out of the Wally wordmark until a square mark is uploaded.
	wally = { image = "rbxassetid://87427394631506", crop = Rect.new(0, 0, 254, 254) },
	-- The logomark, cropped out of the pesde wordmark until a square mark is uploaded.
	pesde = { image = "rbxassetid://125159874176259", crop = Rect.new(0, 0, 154, 154) },
}

-- Returns the mark drawn wherever a registry is named.
const function registryMark(registry: types.Registry): Mark
	return MARKS[registry]
end

return registryMark
