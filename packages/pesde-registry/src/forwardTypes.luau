--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const parseExportedTypes = require(StudioDiscover.Libraries.PackageTypes.parseExportedTypes)
const trim = require(StudioDiscover.Libraries.Core.trim)

--[[
	Returns the `export type` lines that re-export every type `source` exports,
		through `moduleVariable`, the local a link module holds the required module in.
		These are the pesde CLI's rules, so a pesde link reads the way `pesde install`
		would have written it.

	An alias keeps its generic header as written, defaults included, and the reference
		passes each parameter by name. A type function forwards its own parameter names
		as generics, and one with no named parameters is skipped. pesde also copies a
		variadic `...` into those generics, which does not parse, so it is left out.
]]
const function forwardTypes(source: string, moduleVariable: string): { string }
	const lines: { string } = {}

	for _, exported in parseExportedTypes.extractExportedTypes(source) do
		const reference = `{moduleVariable}.{exported.name}`

		if exported.kind == "function" then
			if #exported.parameters == 0 then
				continue
			end

			const list = `<{table.concat(exported.parameters, ", ")}>`
			table.insert(lines, `export type {exported.name}{list} = {reference}{list}`)
			continue
		end

		const params: { string } = {}
		for _, param in parseExportedTypes.splitGenerics(exported.generics) do
			table.insert(params, trim(param))
		end

		if #params == 0 then
			table.insert(lines, `export type {exported.name} = {reference}`)
			continue
		end

		const declaration = `<{table.concat(params, ", ")}>`
		const paramNames = parseExportedTypes.extractParamNames(exported.generics)
		table.insert(lines, `export type {exported.name}{declaration} = {reference}{paramNames}`)
	end

	return lines
end

return forwardTypes
