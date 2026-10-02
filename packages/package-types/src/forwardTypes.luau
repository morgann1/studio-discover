--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const parseExportedTypes = require(StudioDiscover.PackageTypes.parseExportedTypes)

--[[
	Returns the `export type` lines that re-export every type `source` exports,
		through `moduleVariable`, the local a link module holds the required module in.

	A generic default is kept only when every name in it is in scope in the link
		module, and Luau's ordering rule then drops the defaults to its left as well.
		Type functions are forwarded with one generic per parameter.
]]
const function forwardTypes(source: string, moduleVariable: string): { string }
	const exportedTypes = parseExportedTypes.extractExportedTypes(source)

	const resolvedTypes: parseExportedTypes.ResolvedTypes = {}
	for _, exported in exportedTypes do
		resolvedTypes[exported.name] = true
	end

	const lines: { string } = {}
	for _, exported in exportedTypes do
		const reference = `{moduleVariable}.{exported.name}`
		if exported.generics == "" then
			table.insert(lines, `export type {exported.name} = {reference}`)
			continue
		end

		-- The alias's own generics are in scope for its defaults, alongside the forwarded types.
		const scope = table.clone(resolvedTypes)
		for _, param in parseExportedTypes.splitGenerics(exported.generics) do
			const paramName = parseExportedTypes.extractParamName(param)
			if paramName ~= nil then
				scope[paramName] = true
			end
		end

		const declaration = parseExportedTypes.stripUnknownDefaults(exported.generics, scope)
		const paramNames = parseExportedTypes.extractParamNames(exported.generics)
		table.insert(lines, `export type {exported.name}{declaration} = {reference}{paramNames}`)
	end

	return lines
end

return forwardTypes
