--!strict

--[[
	The height of every list row, so lists line up across screens. `single` is a row
		with one line of text, dense enough to sit beside Studio's Asset Manager, and
		`double` fits a name over a detail line. A docked Installed row grows past
		`double` when its detail line wraps.
]]
const rowHeights = table.freeze({
	single = 44,
	double = 56,
})

return rowHeights
