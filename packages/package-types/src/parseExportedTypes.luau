--!strict

--[[
	Reading exported types back out of Luau source.

	This module is pure string work: it never touches an Instance, which is what
		makes it directly testable. `forwardTypes.luau` builds the forwarding lines
		from it, and `init.luau` is the part that knows about link modules and
		`_Index`.
]]

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const trim = require(StudioDiscover.Libraries.Core.trim)

-- The names a forwarded default may use: type names that are in scope in the rewritten link module.
export type ResolvedTypes = { [string]: true? }

--[[
	One `export type` in a module's source.

	`generics` is the alias's own generic header. A type function has no header, so
		it gets one generic per named parameter, `<T0, T1>`, the way upstream forwards
		it.
]]
export type ExportedType = {
	read name: string,
	read generics: string,
	read kind: "alias" | "function",
}

const BUILTIN_TYPES: ResolvedTypes = {
	["any"] = true,
	["boolean"] = true,
	["buffer"] = true,
	["never"] = true,
	["number"] = true,
	["string"] = true,
	["thread"] = true,
	["unknown"] = true,
}
table.freeze(BUILTIN_TYPES)

const function isOpeningBracket(char: string): boolean
	return char == "<" or char == "(" or char == "{" or char == "["
end

-- A `>` right after `-` is a function arrow, not a closing bracket.
const function isClosingBracket(char: string, previous: string): boolean
	return char == ")" or char == "}" or char == "]" or (char == ">" and previous ~= "-")
end

--[[
	Splits "<T, U = string>" into its top-level parameters, ignoring commas nested
		inside brackets or an inner generic list.
]]
const function splitGenerics(generics: string): { string }
	const inner = generics:match("^<(.+)>$")
	if inner == nil then
		return {}
	end

	const params: { string } = {}
	local depth = 0
	local current = ""

	for index = 1, #inner do
		const char = inner:sub(index, index)
		const previous = if index > 1 then inner:sub(index - 1, index - 1) else ""

		if isOpeningBracket(char) then
			depth += 1
			current ..= char
		elseif isClosingBracket(char, previous) then
			depth -= 1
			current ..= char
		elseif char == "," and depth == 0 then
			table.insert(params, current)
			current = ""
		else
			current ..= char
		end
	end

	if current ~= "" then
		table.insert(params, current)
	end

	return params
end

const function extractParamName(param: string): string?
	return param:match("^%s*([%w_]+)")
end

-- Returns the text after a top-level `=` in one generic parameter, if there is one.
const function extractDefaultType(param: string): string?
	local depth = 0

	for index = 1, #param do
		const char = param:sub(index, index)
		const previous = if index > 1 then param:sub(index - 1, index - 1) else ""

		if isOpeningBracket(char) then
			depth += 1
		elseif isClosingBracket(char, previous) then
			depth -= 1
		elseif char == "=" and depth == 0 then
			const rest = trim(param:sub(index + 1))
			return if rest == "" then nil else rest
		end
	end

	return nil
end

--[[
	A default is copied across only when it is a bare type name in scope where the
		rewritten link module is evaluated, or a `true` or `false` singleton. That is
		the whole of wally-package-types' rule, so anything richer, such as `T?` or
		`{ T }`, is dropped even when every name in it resolves.
]]
const function shouldKeepDefault(defaultType: string, resolvedTypes: ResolvedTypes): boolean
	if defaultType == "true" or defaultType == "false" then
		return true
	end

	if defaultType:match("^[%a_][%w_]*$") == nil then
		return false
	end

	return BUILTIN_TYPES[defaultType] ~= nil or resolvedTypes[defaultType] ~= nil
end

-- A forwarded parameter keeps its name, and its `...` when it is a type pack.
const function forwardedParam(param: string): string?
	const name = extractParamName(param)
	if name == nil then
		return nil
	end

	return if param:match("%.%.%.") ~= nil then `{name}...` else name
end

--[[
	Rewrites a generic header so it only keeps defaults that `shouldKeepDefault`
		accepts.

	Luau only allows defaulted generics after every non-defaulted one, so dropping a
		default means dropping every default to its left as well.
]]
const function stripUnknownDefaults(generics: string, resolvedTypes: ResolvedTypes): string
	if generics == "" then
		return ""
	end

	const params = splitGenerics(generics)
	if #params == 0 then
		return generics
	end

	-- Everything up to the last parameter without a keepable default loses its default.
	local lastStrippedIndex = 0
	for index = #params, 1, -1 do
		const defaultType = extractDefaultType(params[index])
		if defaultType == nil or not shouldKeepDefault(defaultType, resolvedTypes) then
			lastStrippedIndex = index
			break
		end
	end

	const result: { string } = {}
	for index, param in params do
		if index <= lastStrippedIndex then
			table.insert(result, forwardedParam(param) or param)
		else
			table.insert(result, trim(param))
		end
	end

	return `<{table.concat(result, ", ")}>`
end

-- Turns a generic declaration into the argument list that forwards it on.
const function extractParamNames(generics: string): string
	if generics == "" then
		return ""
	end

	const names: { string } = {}
	for _, param in splitGenerics(generics) do
		const name = forwardedParam(param)
		if name ~= nil then
			table.insert(names, name)
		end
	end

	return `<{table.concat(names, ", ")}>`
end

--[[
	Turns a type function's parameter list into the generics that forward it.
		Variadic `...` cannot be forwarded as a generic, so it is dropped.
]]
const function typeFunctionGenerics(parameterList: string): string
	const names: { string } = {}
	for param in parameterList:sub(2, -2):gmatch("[^,]+") do
		const name = trim(param)
		if name ~= "" and name ~= "..." then
			table.insert(names, `T{#names}`)
		end
	end

	return `<{table.concat(names, ", ")}>`
end

const function tryOpenLongBracket(source: string, position: number): number?
	if source:sub(position, position) ~= "[" then
		return nil
	end

	local level = 0
	local index = position + 1
	while source:sub(index, index) == "=" do
		level += 1
		index += 1
	end

	return if source:sub(index, index) == "[" then level else nil
end

const function skipLongBracket(source: string, afterOpen: number, level: number): number
	const close = `]{string.rep("=", level)}]`
	const found = source:find(close, afterOpen, true)
	if found == nil then
		return #source + 1
	end

	return found + #close
end

--[[
	Returns the position just past a comment or string literal starting at
		`position`, or nil when `position` is ordinary source. Keeps `export type`
		inside a comment or string from being read as a real declaration.
]]
const function skipStringOrComment(source: string, position: number): number?
	if position > #source then
		return nil
	end

	if source:sub(position, position + 1) == "--" then
		const afterDash = position + 2
		const longLevel = tryOpenLongBracket(source, afterDash)
		if longLevel ~= nil then
			return skipLongBracket(source, afterDash + longLevel + 2, longLevel)
		end

		const newline = source:find("\n", afterDash, true)
		return if newline == nil then #source + 1 else newline
	end

	const longLevel = tryOpenLongBracket(source, position)
	if longLevel ~= nil then
		return skipLongBracket(source, position + longLevel + 2, longLevel)
	end

	const quote = source:sub(position, position)
	if quote ~= "'" and quote ~= '"' then
		return nil
	end

	local index = position + 1
	while index <= #source do
		const char = source:sub(index, index)
		if char == "\\" then
			index += 2
		elseif char == quote or char == "\n" then
			return index + 1
		else
			index += 1
		end
	end

	return #source + 1
end

--[[
	Finds the `>` closing the generic list that opens at `start`, skipping over `->`
		arrows and any brackets or strings in between.
]]
const function readBalancedAngleBrackets(source: string, start: number): number?
	local angleDepth = 0
	local parenDepth = 0
	local braceDepth = 0
	local squareDepth = 0
	local index = start

	while index <= #source do
		const skipped = skipStringOrComment(source, index)
		if skipped ~= nil then
			index = skipped
			continue
		end

		const char = source:sub(index, index)
		const previous = if index > 1 then source:sub(index - 1, index - 1) else ""
		const isTopLevel = parenDepth == 0 and braceDepth == 0 and squareDepth == 0

		if char == "(" then
			parenDepth += 1
		elseif char == ")" then
			parenDepth -= 1
		elseif char == "{" then
			braceDepth += 1
		elseif char == "}" then
			braceDepth -= 1
		elseif char == "[" then
			squareDepth += 1
		elseif char == "]" then
			squareDepth -= 1
		elseif char == "<" and isTopLevel then
			angleDepth += 1
		elseif char == ">" and isTopLevel and previous ~= "-" then
			angleDepth -= 1
			if angleDepth == 0 then
				return index
			end
		end

		index += 1
	end

	return nil
end

-- Returns every `export type` and `export type function` in `source`, in order.
const function extractExportedTypes(source: string): { ExportedType }
	const exported: { ExportedType } = {}
	local index = 1

	while index <= #source do
		const skipped = skipStringOrComment(source, index)
		if skipped ~= nil then
			index = skipped
			continue
		end

		const _, keywordEnd = source:find("^%f[%w_]export%s+type%s+", index)
		if keywordEnd == nil then
			index += 1
			continue
		end

		const _, functionEnd = source:find("^function%s+", keywordEnd + 1)
		const kind: "alias" | "function" = if functionEnd ~= nil then "function" else "alias"
		const nameStart = if functionEnd ~= nil then functionEnd + 1 else keywordEnd + 1

		const _, nameEnd, name = source:find("^([%w_]+)", nameStart)
		if name == nil or nameEnd == nil then
			index = keywordEnd + 1
			continue
		end

		const afterName = nameEnd + 1
		local generics = ""
		if kind == "function" then
			const parameterList = source:match("^%s*(%b())", afterName)
			if parameterList ~= nil then
				generics = typeFunctionGenerics(parameterList)
			end
		else
			const nextNonSpace = source:find("%S", afterName)
			if nextNonSpace ~= nil and source:sub(nextNonSpace, nextNonSpace) == "<" then
				const genericsEnd = readBalancedAngleBrackets(source, nextNonSpace)
				if genericsEnd ~= nil then
					generics = source:sub(nextNonSpace, genericsEnd)
				end
			end
		end

		table.insert(exported, { name = name, generics = generics, kind = kind })
		index = afterName
	end

	return exported
end

const parseExportedTypes = table.freeze({
	extractDefaultType = extractDefaultType,
	extractExportedTypes = extractExportedTypes,
	extractParamName = extractParamName,
	extractParamNames = extractParamNames,
	shouldKeepDefault = shouldKeepDefault,
	splitGenerics = splitGenerics,
	stripUnknownDefaults = stripUnknownDefaults,
})

return parseExportedTypes
