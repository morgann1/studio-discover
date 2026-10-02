--!strict

--[[
	A Luau port of the wally-package-types CLI.

	Wally writes each dependency into `Packages` as a link module that requires the
		real content out of `_Index`. A plain require forwards values but not exported
		types, so `require(Packages.Foo).Bar` type-checks and `Packages.Foo.Bar` as a
		type does not. `processLinkAsync` rewrites a link module to re-export the target's
		types alongside the value it already returned.

	Call it on one link module at a time, after the tree is in the DataModel.
]]

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const createLogger = require(StudioDiscover.Core.createLogger)
const forwardTypes = require(StudioDiscover.PackageTypes.forwardTypes)
const parseLink = require(StudioDiscover.PackageTypes.parseLink)
const setScriptSourceAsync = require(StudioDiscover.Core.setScriptSourceAsync)

const logger = createLogger.createLogger("packageTypes")

const function resolveLink(linkModule: ModuleScript, linkPackageId: string, moduleName: string): ModuleScript?
	const parent = linkModule.Parent
	if parent == nil then
		logger.warn(`resolveLink: "{linkModule:GetFullName()}" has no parent`)
		return nil
	end

	-- A root link sits beside `_Index`, and a dependency link sits in a package folder inside it.
	const indexFolder = parent:FindFirstChild("_Index") or parent.Parent
	if indexFolder == nil then
		logger.warn(`resolveLink: "{linkModule:GetFullName()}" has no sibling or ancestor _Index folder`)
		return nil
	end

	const packageFolder = indexFolder:FindFirstChild(linkPackageId)
	if packageFolder == nil then
		logger.warn(
			`resolveLink: "{linkModule:GetFullName()}" targets "{linkPackageId}" but no such package under "{indexFolder:GetFullName()}"`
		)
		return nil
	end

	const target = packageFolder:FindFirstChild(moduleName)
	if target ~= nil and target:IsA("ModuleScript") then
		return target
	end

	logger.warn(
		`resolveLink: "{linkModule:GetFullName()}" target module "{moduleName}" not found or not a ModuleScript in "{packageFolder:GetFullName()}"`
	)
	return nil
end

--[[
	Rewrites `linkModule` in place so it re-exports its target's types. Leaves the module
		untouched when there is nothing to forward.
]]
const function processLinkAsync(linkModule: ModuleScript)
	const link = parseLink(linkModule.Source)
	if link == nil then
		logger.debug(`skip "{linkModule.Name}": source does not match link pattern`)
		return
	end

	const linkPackageId, moduleName = link.packageId, link.moduleName
	const target = resolveLink(linkModule, linkPackageId, moduleName)
	if target == nil then
		logger.debug(`skip "{linkModule.Name}": could not resolve target {linkPackageId}.{moduleName}`)
		return
	end

	const forwards = forwardTypes(target.Source, "REQUIRED_MODULE")
	if #forwards == 0 then
		logger.debug(`skip "{linkModule.Name}": target {linkPackageId}.{moduleName} has no exported types`)
		return
	end

	const lines = { `local REQUIRED_MODULE = require({link.indexPath}["{linkPackageId}"]["{moduleName}"])` }
	table.move(forwards, 1, #forwards, #lines + 1, lines)
	table.insert(lines, "return REQUIRED_MODULE")

	const ok, err = setScriptSourceAsync(linkModule, table.concat(lines, "\n"))
	if not ok then
		logger.warn(`could not rewrite "{linkModule.Name}" with type exports: {err}`)
		return
	end

	logger.debug(`rewrote "{linkModule.Name}" with {#forwards} exported type(s) from {linkPackageId}.{moduleName}`)
end

return processLinkAsync
