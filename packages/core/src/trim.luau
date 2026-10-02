--!strict

-- Returns `text` without leading or trailing whitespace.
const function trim(text: string): string
	return text:match("^%s*(.-)%s*$") or text
end

return trim
