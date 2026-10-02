--!strict

--[[
	One column of a table. A column with a `width` is that many pixels wide, and the
		columns without one share the width that remains.
]]
export type Column = {
	read key: string,
	read label: string,
	read width: number?,
}

return nil
