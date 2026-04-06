local PackageTypes = {}

local function stripGenericDefaults(generics: string): string
	if generics == "" then
		return ""
	end

	local inner = generics:match("^<(.+)>$")
	if not inner then
		return generics
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

	local names = {}
	for _, param in params do
		local name = param:match("^%s*([%w_]+)")
		if name then
			table.insert(names, name)
		end
	end

	return "<" .. table.concat(names, ", ") .. ">"
end

function PackageTypes.extractExportedTypes(
	source: string
): { { name: string, generics: string, genericsStripped: string } }
	local types = {}

	for line in source:gmatch("[^\n]+") do
		local name, generics = line:match("^%s*export%s+type%s+([%w_]+)(%b<>)")
		if not name then
			name = line:match("^%s*export%s+type%s+([%w_]+)%s*=")
			generics = nil
		end
		if name then
			local g = generics or ""
			table.insert(types, {
				name = name,
				generics = g,
				genericsStripped = stripGenericDefaults(g),
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

	local pkgFolder = indexFolder:FindFirstChild(packageId)
	if not pkgFolder then
		return nil
	end

	local target = pkgFolder:FindFirstChild(moduleName)
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

	local requirePath = `{prefix}["{packageId}"]["{moduleName}"]`
	local lines = {}
	table.insert(lines, `local REQUIRED_MODULE = require({requirePath})`)

	for _, typeInfo in types do
		if typeInfo.generics ~= "" then
			table.insert(
				lines,
				`export type {typeInfo.name}{typeInfo.generics} = REQUIRED_MODULE.{typeInfo.name}{typeInfo.genericsStripped}`
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
