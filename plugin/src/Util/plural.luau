--!strict

-- A count with its noun, as in "1 update" or "3 updates".
const function plural(count: number, noun: string): string
	return if count == 1 then `1 {noun}` else `{count} {noun}s`
end

return plural
