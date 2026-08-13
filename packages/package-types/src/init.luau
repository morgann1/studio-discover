--!strict

--[[
	A Luau port of the wally-package-types CLI.

	Wally writes each dependency into `Packages` as a link module that requires the
	real content out of `_Index`. A plain require forwards values but not exported
	types, so `require(Packages.Foo).Bar` type-checks and `Packages.Foo.Bar` as a
	type does not. `processLink` rewrites a link module to re-export the target's
	types alongside the value it already returned.

	Call it on one link module at a time, after the tree is in the DataModel.
]]

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local createLogger = require(StudioDiscover.Core.createLogger)
local setScriptSource = require(StudioDiscover.Core.setScriptSource)

local parseExportedTypes = require(script.parseExportedTypes)

local logger = createLogger.createLogger("packageTypes")

local extractExportedTypes = parseExportedTypes.extractExportedTypes
local extractParamName = parseExportedTypes.extractParamName
local extractParamNames = parseExportedTypes.extractParamNames
local splitGenerics = parseExportedTypes.splitGenerics
local stripUnknownDefaults = parseExportedTypes.stripUnknownDefaults

-- Returns the require prefix, the `_Index` package id, and the module name from a
-- link module's source, or nils when the source is not a link.
local function parseLinkRequire(source: string): (string?, string?, string?)
	return source:match('require%((.-)%["([^"]+)"%]%["([^"]+)"%]%)')
end

local function resolveLink(linkModule: ModuleScript): ModuleScript?
	local _, linkPackageId, moduleName = parseLinkRequire(linkModule.Source)
	if linkPackageId == nil or moduleName == nil then
		logger.debug(`resolveLink: "{linkModule:GetFullName()}" source is not a link pattern`)
		return nil
	end

	local parent = linkModule.Parent
	if parent == nil then
		logger.warn(`resolveLink: "{linkModule:GetFullName()}" has no parent`)
		return nil
	end
	local indexFolder = parent:FindFirstChild("_Index")
	if indexFolder == nil then
		indexFolder = parent.Parent
	end
	if indexFolder == nil then
		logger.warn(`resolveLink: "{linkModule:GetFullName()}" has no sibling or ancestor _Index folder`)
		return nil
	end

	local packageFolder = indexFolder:FindFirstChild(linkPackageId :: string)
	if packageFolder == nil then
		logger.warn(
			`resolveLink: "{linkModule:GetFullName()}" targets "{linkPackageId}" but no such package under "{indexFolder:GetFullName()}"`
		)
		return nil
	end

	local target = packageFolder:FindFirstChild(moduleName :: string)
	if target ~= nil and target:IsA("ModuleScript") then
		return target
	end
	logger.warn(
		`resolveLink: "{linkModule:GetFullName()}" target module "{moduleName}" not found or not a ModuleScript in "{packageFolder:GetFullName()}"`
	)
	return nil
end

-- Rewrites `linkModule` in place so it re-exports its target's types. Returns
-- false and leaves the module untouched when there is nothing to forward.
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
		if info.kind == "alias" then
			resolvedTypes[info.name] = true
		end
	end

	local requirePath = `{prefix}["{linkPackageId}"]["{moduleName}"]`
	local lines: { string } = {}
	table.insert(lines, `local REQUIRED_MODULE = require({requirePath})`)

	for _, info in exported do
		if info.kind ~= "alias" then
			continue
		end
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

return processLink
