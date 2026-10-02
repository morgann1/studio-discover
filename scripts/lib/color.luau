--!strict

--[[
	ANSI styling for script output. Styles nest, so `color.bold(color.red(text))`
		prints bold red text.
]]

local ESCAPE = string.char(27)

export type Styler = (text: string) -> string

local function styler(opener: number, closer: number): Styler
	local open = `{ESCAPE}[{opener}m`
	local close = `{ESCAPE}[{closer}m`

	return function(text: string)
		return `{open}{text}{close}`
	end
end

return table.freeze({
	bold = styler(1, 22),
	dim = styler(2, 22),

	red = styler(31, 39),
	green = styler(32, 39),
	yellow = styler(33, 39),
	cyan = styler(36, 39),
	white = styler(37, 39),
})
