--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local createLogger = require(StudioDiscover.Source.Util.createLogger)
local setScriptSource = require(StudioDiscover.Source.Util.setScriptSource)

local logger = createLogger.createLogger("wally.installer.processTypes")

local BUILTIN_TYPES: { [string]: boolean } = {
	["any"] = true,
	["boolean"] = true,
	["buffer"] = true,
	["never"] = true,
	["number"] = true,
	["string"] = true,
	["thread"] = true,
	["unknown"] = true,
}

local function splitGenerics(generics: string): { string }
	local inner = generics:match("^<(.+)>$")
	if inner == nil then
		return {}
	end

	local params: { string } = {}
	local depth = 0
	local current = ""
	for i = 1, #inner do
		local ch = inner:sub(i, i)
		if ch == "<" or ch == "(" then
			depth += 1
			current ..= ch
		elseif ch == ">" or ch == ")" then
			depth -= 1
			current ..= ch
		elseif ch == "," and depth == 0 then
			table.insert(params, current)
			current = ""
		else
			current ..= ch
		end
	end
	if current ~= "" then
		table.insert(params, current)
	end
	return params
end

local function extractParamName(param: string): string?
	return param:match("^%s*([%w_]+)")
end

local function extractDefaultType(param: string): string?
	return param:match("=%s*([%w_%.]+)%s*$")
end

local function shouldKeepDefault(defaultType: string, resolvedTypes: { [string]: true }): boolean
	return BUILTIN_TYPES[defaultType] == true or resolvedTypes[defaultType] == true
end

local function stripUnknownDefaults(generics: string, resolvedTypes: { [string]: true }): string
	if generics == "" then
		return ""
	end

	local params = splitGenerics(generics)
	if #params == 0 then
		return generics
	end

	local hasDefault: { boolean } = {}
	local keepDefault: { boolean } = {}
	for i, param in params do
		local defaultType = extractDefaultType(param)
		hasDefault[i] = defaultType ~= nil
		keepDefault[i] = defaultType ~= nil and shouldKeepDefault(defaultType :: string, resolvedTypes)
	end

	local lastStrippedIndex = 0
	for i = #params, 1, -1 do
		if hasDefault[i] and not keepDefault[i] then
			lastStrippedIndex = i
			break
		end
		if not hasDefault[i] then
			lastStrippedIndex = i
			break
		end
	end

	local result: { string } = {}
	for i, param in params do
		if i <= lastStrippedIndex then
			local name = extractParamName(param)
			local isVariadic = param:match("%.%.%.") ~= nil
			if isVariadic then
				table.insert(result, (name or param) .. "...")
			else
				table.insert(result, name or param)
			end
		else
			table.insert(result, param)
		end
	end

	return "<" .. table.concat(result, ", ") .. ">"
end

local function extractParamNames(generics: string): string
	if generics == "" then
		return ""
	end

	local params = splitGenerics(generics)
	local names: { string } = {}
	for _, param in params do
		local name = extractParamName(param)
		if name ~= nil then
			local isVariadic = param:match("%.%.%.") ~= nil
			table.insert(names, if isVariadic then name .. "..." else name)
		end
	end
	return "<" .. table.concat(names, ", ") .. ">"
end

type ExportedType = {
	name: string,
	generics: string,
}

local function extractExportedTypes(source: string): { ExportedType }
	local types: { ExportedType } = {}
	for line in source:gmatch("[^\n]+") do
		local name, generics = line:match("^%s*export%s+type%s+([%w_]+)(%b<>)")
		if name == nil then
			name = line:match("^%s*export%s+type%s+([%w_]+)%s*=")
			generics = nil
		end
		if name ~= nil then
			table.insert(types, {
				name = name :: string,
				generics = generics or "",
			})
		end
	end
	return types
end

local function parseLinkRequire(source: string): (string?, string?, string?)
	return source:match('require%((.-)%["([^"]+)"%]%["([^"]+)"%]%)')
end

local function resolveLink(linkModule: ModuleScript): ModuleScript?
	local _, linkPackageId, moduleName = parseLinkRequire(linkModule.Source)
	if linkPackageId == nil or moduleName == nil then
		return nil
	end

	local parent = linkModule.Parent
	if parent == nil then
		return nil
	end
	local indexFolder = parent:FindFirstChild("_Index")
	if indexFolder == nil then
		indexFolder = parent.Parent
	end
	if indexFolder == nil then
		return nil
	end

	local packageFolder = indexFolder:FindFirstChild(linkPackageId :: string)
	if packageFolder == nil then
		return nil
	end

	local target = packageFolder:FindFirstChild(moduleName :: string)
	if target ~= nil and target:IsA("ModuleScript") then
		return target
	end
	return nil
end

local function processLink(linkModule: ModuleScript): boolean
	local prefix, linkPackageId, moduleName = parseLinkRequire(linkModule.Source)
	if prefix == nil or linkPackageId == nil or moduleName == nil then
		logger.debug(`skip "{linkModule.Name}": source does not match link pattern`)
		return false
	end

	local target = resolveLink(linkModule)
	if target == nil then
		logger.debug(`skip "{linkModule.Name}": could not resolve target {linkPackageId}.{moduleName}`)
		return false
	end

	local exported = extractExportedTypes(target.Source)
	if #exported == 0 then
		logger.debug(`skip "{linkModule.Name}": target {linkPackageId}.{moduleName} has no exported types`)
		return false
	end

	local resolvedTypes: { [string]: true } = {}
	for _, info in exported do
		resolvedTypes[info.name] = true
	end

	local requirePath = `{prefix}["{linkPackageId}"]["{moduleName}"]`
	local lines: { string } = {}
	table.insert(lines, `local REQUIRED_MODULE = require({requirePath})`)

	for _, info in exported do
		if info.generics ~= "" then
			local paramNames = extractParamNames(info.generics)

			local paramResolvedTypes = table.clone(resolvedTypes)
			for _, param in splitGenerics(info.generics) do
				local paramName = extractParamName(param)
				if paramName ~= nil then
					paramResolvedTypes[paramName] = true
				end
			end

			local declaration = stripUnknownDefaults(info.generics, paramResolvedTypes)
			table.insert(lines, `export type {info.name}{declaration} = REQUIRED_MODULE.{info.name}{paramNames}`)
		else
			table.insert(lines, `export type {info.name} = REQUIRED_MODULE.{info.name}`)
		end
	end

	table.insert(lines, "return REQUIRED_MODULE")
	local ok, err = setScriptSource(linkModule, table.concat(lines, "\n"))
	if not ok then
		logger.warn(`could not rewrite "{linkModule.Name}" with type exports: {err}`)
		return false
	end
	logger.debug(`rewrote "{linkModule.Name}" with {#exported} exported type(s) from {linkPackageId}.{moduleName}`)
	return true
end

return table.freeze({
	processLink = processLink,
})
