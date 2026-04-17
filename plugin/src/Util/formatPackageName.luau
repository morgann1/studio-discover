--!strict

export type NamingConvention = "Normal" | "PascalCase" | "camelCase" | "snake_case"

export type FormatOptions = {
	hint: string?,
	overrides: { [string]: string }?,
}

local PASCAL_OVERRIDES: { [string]: string? } = {
	goodsignal = "GoodSignal",
	roactrouter = "RoactRouter",
	roactrodux = "RoactRodux",
	roactnavigation = "RoactNavigation",
	testez = "TestEZ",
	wally = "Wally",
}

local function toPascalCase(str: string): string
	local capitalize: any = function(first: string, rest: string): string
		return first:upper() .. rest
	end
	return (str:gsub("(%a)([%w]*)", capitalize):gsub("[-_]+", ""))
end

local function toCamelCase(str: string): string
	local pascal = toPascalCase(str)
	return pascal:sub(1, 1):lower() .. pascal:sub(2)
end

local function toSnakeCase(str: string): string
	return (str:gsub("[-]+", "_"):lower())
end

local function toPascalCaseWithHint(name: string, hint: string?): string
	if hint ~= nil and hint ~= "" then
		local normalizedName = string.lower((string.gsub(name, "[-_]+", "")))
		local normalizedHint = string.lower((string.gsub(hint, "[-_]+", "")))
		if normalizedName == normalizedHint then
			return (string.gsub(hint, "[-_]+", ""))
		end
	end

	local override = PASCAL_OVERRIDES[string.lower(name)]
	if override ~= nil then
		return override
	end

	return toPascalCase(name)
end

local function formatPackageName(name: string, convention: NamingConvention, options: FormatOptions?): string
	if options ~= nil and options.overrides ~= nil then
		local key = string.lower(name)
		local override = options.overrides[key]
		if override ~= nil and override ~= "" then
			return override
		end
	end

	if convention == "PascalCase" then
		return toPascalCaseWithHint(name, options and options.hint)
	elseif convention == "camelCase" then
		return toCamelCase(name)
	elseif convention == "snake_case" then
		return toSnakeCase(name)
	else
		return name
	end
end

return formatPackageName
