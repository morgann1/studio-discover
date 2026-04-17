--!strict

local function formatPackageKey(scope: string, name: string): string
	return `{scope}/{name}`
end

return formatPackageKey
