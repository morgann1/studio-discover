--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local createLogger = require(StudioDiscover.Source.Util.createLogger)

local logger = createLogger.createLogger("installer.processTypes")

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

type Token = {
	kind: "ident" | "num" | "str" | "punct",
	value: string,
}

local function tokenize(source: string): { Token }
	local tokens: { Token } = {}
	local i = 1
	local n = #source
	while i <= n do
		local c = source:sub(i, i)

		if c == " " or c == "\t" or c == "\n" or c == "\r" then
			i += 1
			continue
		end

		if c == "-" and source:sub(i + 1, i + 1) == "-" then
			local after = i + 2
			if source:sub(after, after) == "[" then
				local eqStart = after + 1
				local eqEnd = eqStart
				while source:sub(eqEnd, eqEnd) == "=" do
					eqEnd += 1
				end
				if source:sub(eqEnd, eqEnd) == "[" then
					local eqCount = eqEnd - eqStart
					local closer = "]" .. string.rep("=", eqCount) .. "]"
					local closeIdx = source:find(closer, eqEnd + 1, true)
					i = if closeIdx == nil then n + 1 else closeIdx + #closer
					continue
				end
			end
			local newline = source:find("\n", after, true)
			i = if newline == nil then n + 1 else newline + 1
			continue
		end

		if c == '"' or c == "'" then
			local quote = c
			local j = i + 1
			while j <= n do
				local ch = source:sub(j, j)
				if ch == "\\" then
					j += 2
				elseif ch == quote then
					j += 1
					break
				elseif ch == "\n" then
					break
				else
					j += 1
				end
			end
			table.insert(tokens, { kind = "str", value = "" })
			i = j
			continue
		end

		if c == "[" then
			local eqStart = i + 1
			local eqEnd = eqStart
			while source:sub(eqEnd, eqEnd) == "=" do
				eqEnd += 1
			end
			if source:sub(eqEnd, eqEnd) == "[" then
				local eqCount = eqEnd - eqStart
				local closer = "]" .. string.rep("=", eqCount) .. "]"
				local closeIdx = source:find(closer, eqEnd + 1, true)
				i = if closeIdx == nil then n + 1 else closeIdx + #closer
				table.insert(tokens, { kind = "str", value = "" })
				continue
			end
			table.insert(tokens, { kind = "punct", value = "[" })
			i += 1
			continue
		end

		if c:match("[%a_]") ~= nil then
			local j = i + 1
			while j <= n and source:sub(j, j):match("[%w_]") ~= nil do
				j += 1
			end
			table.insert(tokens, { kind = "ident", value = source:sub(i, j - 1) })
			i = j
			continue
		end

		if c:match("%d") ~= nil then
			local j = i + 1
			while j <= n and source:sub(j, j):match("[%w_.]") ~= nil do
				j += 1
			end
			table.insert(tokens, { kind = "num", value = source:sub(i, j - 1) })
			i = j
			continue
		end

		if c == "." and source:sub(i + 1, i + 2) == ".." then
			table.insert(tokens, { kind = "punct", value = "..." })
			i += 3
			continue
		end

		if c == "-" and source:sub(i + 1, i + 1) == ">" then
			table.insert(tokens, { kind = "punct", value = "->" })
			i += 2
			continue
		end

		if c == "." and source:sub(i + 1, i + 1) == "." then
			table.insert(tokens, { kind = "punct", value = ".." })
			i += 2
			continue
		end

		table.insert(tokens, { kind = "punct", value = c } :: Token)
		i += 1
	end
	return tokens
end

type GenericParam = {
	name: string,
	variadic: boolean,
	hasDefault: boolean,
	bareDefault: string?,
}

type ExportedType = {
	name: string,
	genericParams: { GenericParam },
}

local function extractBareIdent(tokens: { Token }): string?
	if #tokens == 0 or tokens[1].kind ~= "ident" then
		return nil
	end
	local parts: { string } = { tokens[1].value }
	local i = 2
	while i <= #tokens do
		local dot = tokens[i]
		if dot.kind ~= "punct" or dot.value ~= "." then
			return nil
		end
		i += 1
		local after = tokens[i]
		if after == nil or after.kind ~= "ident" then
			return nil
		end
		table.insert(parts, after.value)
		i += 1
	end
	return table.concat(parts, ".")
end

local function parseOneGenericParam(tokens: { Token }): GenericParam?
	if #tokens == 0 or tokens[1].kind ~= "ident" then
		return nil
	end
	local name = tokens[1].value
	local variadic = false
	local hasDefault = false
	local bareDefault: string? = nil

	local i = 2
	local next1 = tokens[i]
	if next1 ~= nil and next1.kind == "punct" and next1.value == "..." then
		variadic = true
		i += 1
	end
	local next2 = tokens[i]
	if next2 ~= nil and next2.kind == "punct" and next2.value == "=" then
		hasDefault = true
		local defaultTokens: { Token } = {}
		for j = i + 1, #tokens do
			table.insert(defaultTokens, tokens[j])
		end
		bareDefault = extractBareIdent(defaultTokens)
	end

	return {
		name = name,
		variadic = variadic,
		hasDefault = hasDefault,
		bareDefault = bareDefault,
	}
end

local function parseGenerics(tokens: { Token }, startIdx: number): ({ GenericParam }, number)
	local params: { GenericParam } = {}
	local i = startIdx + 1
	local depth = 0
	local paramStart = i

	local function finishParam(endExclusive: number)
		if endExclusive <= paramStart then
			return
		end
		local sub: { Token } = {}
		for k = paramStart, endExclusive - 1 do
			table.insert(sub, tokens[k])
		end
		local parsed = parseOneGenericParam(sub)
		if parsed ~= nil then
			table.insert(params, parsed)
		end
	end

	while i <= #tokens do
		local t = tokens[i]
		if t.kind == "punct" then
			local v = t.value
			if v == "(" or v == "{" or v == "[" or v == "<" then
				depth += 1
			elseif v == ")" or v == "}" or v == "]" then
				depth -= 1
			elseif v == ">" then
				if depth == 0 then
					finishParam(i)
					return params, i
				else
					depth -= 1
				end
			elseif v == "," and depth == 0 then
				finishParam(i)
				paramStart = i + 1
			end
		end
		i += 1
	end
	return params, i
end

local function extractExportedTypes(source: string): { ExportedType }
	local tokens = tokenize(source)
	local result: { ExportedType } = {}
	local i = 1
	while i <= #tokens do
		local t1 = tokens[i]
		local t2 = tokens[i + 1]
		local t3 = tokens[i + 2]
		if
			t1 ~= nil
			and t1.kind == "ident"
			and t1.value == "export"
			and t2 ~= nil
			and t2.kind == "ident"
			and t2.value == "type"
			and t3 ~= nil
			and t3.kind == "ident"
		then
			local name = t3.value
			local j = i + 3
			local generics: { GenericParam } = {}
			local maybeOpen = tokens[j]
			if maybeOpen ~= nil and maybeOpen.kind == "punct" and maybeOpen.value == "<" then
				local endIdx
				generics, endIdx = parseGenerics(tokens, j)
				j = endIdx + 1
			end
			local eq = tokens[j]
			if eq ~= nil and eq.kind == "punct" and eq.value == "=" then
				table.insert(result, { name = name, genericParams = generics })
				i = j + 1
				continue
			end
		end
		i += 1
	end
	return result
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
		if #info.genericParams == 0 then
			table.insert(lines, `export type {info.name} = REQUIRED_MODULE.{info.name}`)
		else
			local paramResolvedTypes = table.clone(resolvedTypes)
			for _, p in info.genericParams do
				paramResolvedTypes[p.name] = true
			end

			local lastStrippedIndex = 0
			for i = #info.genericParams, 1, -1 do
				local p = info.genericParams[i]
				local bare = p.bareDefault
				local keep = bare ~= nil and (BUILTIN_TYPES[bare] == true or paramResolvedTypes[bare] == true)
				if p.hasDefault and not keep then
					lastStrippedIndex = i
					break
				end
				if not p.hasDefault then
					lastStrippedIndex = i
					break
				end
			end

			local declParts: { string } = {}
			local refParts: { string } = {}
			for i, p in info.genericParams do
				table.insert(refParts, if p.variadic then p.name .. "..." else p.name)
				if i <= lastStrippedIndex then
					table.insert(declParts, if p.variadic then p.name .. "..." else p.name)
				else
					table.insert(declParts, `{p.name} = {p.bareDefault :: string}`)
				end
			end

			local declaration = "<" .. table.concat(declParts, ", ") .. ">"
			local refs = "<" .. table.concat(refParts, ", ") .. ">"
			table.insert(lines, `export type {info.name}{declaration} = REQUIRED_MODULE.{info.name}{refs}`)
		end
	end

	table.insert(lines, "return REQUIRED_MODULE")
	linkModule.Source = table.concat(lines, "\n")
	logger.debug(`rewrote "{linkModule.Name}" with {#exported} exported type(s) from {linkPackageId}.{moduleName}`)
	return true
end

return table.freeze({
	processLink = processLink,
})
