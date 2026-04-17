local BUILTIN_TYPES = {
	["any"] = true,
	["boolean"] = true,
	["buffer"] = true,
	["never"] = true,
	["number"] = true,
	["string"] = true,
	["thread"] = true,
	["unknown"] = true,
}

local PackageTypes = {}

local function splitGenerics(generics: string): { string }
	local inner = generics:match("^<(.+)>$")
	if not inner then
		return {}
	end

	local params = {}
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

	local hasDefault = {}
	local keepDefault = {}
	for i, param in params do
		local defaultType = extractDefaultType(param)
		hasDefault[i] = defaultType ~= nil
		keepDefault[i] = defaultType ~= nil and shouldKeepDefault(defaultType, resolvedTypes)
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

	local result = {}
	for i, param in params do
		if i <= lastStrippedIndex then
			local name = extractParamName(param)
			local isVariadic = param:match("%.%.%.") ~= nil
			if isVariadic then
				table.insert(result, name .. "...")
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
	local names = {}
	for _, param in params do
		local name = extractParamName(param)
		if name then
			local isVariadic = param:match("%.%.%.") ~= nil
			table.insert(names, if isVariadic then name .. "..." else name)
		end
	end
	return "<" .. table.concat(names, ", ") .. ">"
end

function PackageTypes.extractExportedTypes(source: string): { { name: string, generics: string } }
	local types = {}

	for line in source:gmatch("[^\n]+") do
		local name, generics = line:match("^%s*export%s+type%s+([%w_]+)(%b<>)")
		if not name then
			name = line:match("^%s*export%s+type%s+([%w_]+)%s*=")
			generics = nil
		end
		if name then
			table.insert(types, {
				name = name,
				generics = generics or "",
			})
		end
	end

	return types
end

function PackageTypes.parseLinkRequire(source: string): (string?, string?, string?)
	local prefix, packageId, moduleName = source:match('require%((.-)%["([^"]+)"%]%["([^"]+)"%]%)')
	return prefix, packageId, moduleName
end

function PackageTypes.resolveLink(linkModule: ModuleScript): ModuleScript?
	local _, packageId, moduleName = PackageTypes.parseLinkRequire(linkModule.Source)
	if not packageId or not moduleName then
		return nil
	end

	local parent = linkModule.Parent
	local indexFolder = parent:FindFirstChild("_Index")
	if not indexFolder then
		indexFolder = parent.Parent
	end
	if not indexFolder then
		return nil
	end

	local packageFolder = indexFolder:FindFirstChild(packageId)
	if not packageFolder then
		return nil
	end

	local target = packageFolder:FindFirstChild(moduleName)
	if target and target:IsA("ModuleScript") then
		return target
	end

	return nil
end

function PackageTypes.processLink(linkModule: ModuleScript): boolean
	local prefix, packageId, moduleName = PackageTypes.parseLinkRequire(linkModule.Source)
	if not prefix or not packageId or not moduleName then
		return false
	end

	local target = PackageTypes.resolveLink(linkModule)
	if not target then
		return false
	end

	local types = PackageTypes.extractExportedTypes(target.Source)
	if #types == 0 then
		return false
	end

	local resolvedTypes: { [string]: true } = {}
	for _, typeInfo in types do
		resolvedTypes[typeInfo.name] = true
	end

	local requirePath = `{prefix}["{packageId}"]["{moduleName}"]`
	local lines = {}
	table.insert(lines, `local REQUIRED_MODULE = require({requirePath})`)

	for _, typeInfo in types do
		if typeInfo.generics ~= "" then
			local paramNames = extractParamNames(typeInfo.generics)

			local paramResolvedTypes = table.clone(resolvedTypes)
			for _, param in splitGenerics(typeInfo.generics) do
				local paramName = extractParamName(param)
				if paramName then
					paramResolvedTypes[paramName] = true
				end
			end

			local declaration = stripUnknownDefaults(typeInfo.generics, paramResolvedTypes)
			table.insert(
				lines,
				`export type {typeInfo.name}{declaration} = REQUIRED_MODULE.{typeInfo.name}{paramNames}`
			)
		else
			table.insert(lines, `export type {typeInfo.name} = REQUIRED_MODULE.{typeInfo.name}`)
		end
	end

	table.insert(lines, "return REQUIRED_MODULE")
	linkModule.Source = table.concat(lines, "\n")
	return true
end

function PackageTypes.processFolder(packagesFolder: Folder): number
	local count = 0
	for _, child in packagesFolder:GetChildren() do
		if child:IsA("ModuleScript") and child.Name ~= "_Index" then
			if PackageTypes.processLink(child) then
				count += 1
			end
		end
	end
	return count
end

return PackageTypes
