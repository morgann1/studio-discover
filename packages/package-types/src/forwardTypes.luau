--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const parseExportedTypes = require(StudioDiscover.Libraries.PackageTypes.parseExportedTypes)

--[[
	Returns the `export type` lines that re-export every type `source` exports,
		through `moduleVariable`, the local a link module holds the required module in.
		These are wally-package-types' rules, so a Wally link reads the way the CLI
		would have rewritten it.

	A generic default is kept only when it is a bare type name in scope in the link
		module, or `true` or `false`. Luau's ordering rule then drops the defaults to
		the left of a dropped one as well. A type function gets one generic per
		parameter, named by position: `<T0, T1>`.
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

		if exported.kind == "function" then
			const generics: { string } = {}
			for index = 1, #exported.parameters do
				table.insert(generics, `T{index - 1}`)
			end

			const list = `<{table.concat(generics, ", ")}>`
			table.insert(lines, `export type {exported.name}{list} = {reference}{list}`)
			continue
		end

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
