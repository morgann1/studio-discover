--!strict

-- Splits a package id from `formatPackageId` back into its npm name and version, or returns nils.
const function parsePackageId(packageId: string): (string?, string?)
	const name, version = packageId:match("^(.+)@([^@]+)$")
	return name, version
end

return parsePackageId
