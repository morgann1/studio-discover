--!strict

type Kind = "pesde" | "wally"

local function formatPesdeName(scope: string, name: string): string
	return `{scope}+{name}`
end

local function formatWallyName(scope: string, name: string, version: string): string
	return `{scope}_{name}@{version}`
end

local function formatOuter(kind: Kind, scope: string, name: string, version: string): string
	if kind == "wally" then
		return formatWallyName(scope, name, version)
	end
	return formatPesdeName(scope, name)
end

return table.freeze({
	formatPesdeName = formatPesdeName,
	formatWallyName = formatWallyName,
	formatOuter = formatOuter,
})
