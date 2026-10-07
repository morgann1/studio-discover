--!strict

-- The npm name of a package Discover lists as `scope/name`, such as "@quenty/maid".
const function npmName(scope: string, name: string): string
	return `@{scope}/{name}`
end

return npmName
