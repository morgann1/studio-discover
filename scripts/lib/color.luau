--!strict

--[[
	ANSI styling for script output. Styles nest, so `color.bold(color.red(text))`
		prints bold red text.
]]

const ESCAPE = string.char(27)

export type Styler = (text: string) -> string

const function styler(opener: number, closer: number): Styler
	const open = `{ESCAPE}[{opener}m`
	const close = `{ESCAPE}[{closer}m`

	return function(text: string)
		return `{open}{text}{close}`
	end
end

const color = table.freeze({
	bold = styler(1, 22),
	dim = styler(2, 22),

	red = styler(31, 39),
	green = styler(32, 39),
	yellow = styler(33, 39),
	cyan = styler(36, 39),
	white = styler(37, 39),
})

return color
