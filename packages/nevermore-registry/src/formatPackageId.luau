--!strict

-- The id resolve keys a package by, which is also what npm calls it: "@quenty/maid@3.12.1".
const function formatPackageId(name: string, version: string): string
	return `{name}@{version}`
end

return formatPackageId
