--!strict

local function trimmed(s: string): string
	return s:match("^%s*(.-)%s*$") or s
end

local function stripDefault(param: string): string
	local before = param:match("^([^=]*)") or param
	return trimmed(before)
end

local function splitTopLevelCommas(inside: string): { string }
	local parts: { string } = {}
	local depth = 0
	local start = 1
	local i = 1
	while i <= #inside do
		local c = string.sub(inside, i, i)
		if c == "<" then
			depth += 1
		elseif c == ">" then
			depth -= 1
		elseif c == "," and depth == 0 then
			table.insert(parts, string.sub(inside, start, i - 1))
			start = i + 1
		end
		i += 1
	end
	local tail = string.sub(inside, start)
	if trimmed(tail) ~= "" then
		table.insert(parts, tail)
	end
	return parts
end

local function isWordChar(c: string): boolean
	return c:match("[%w_]") ~= nil
end

local function extractExports(source: string): { string }
	local exports: { string } = {}
	local len = #source
	local pos = 1

	while pos <= len do
		local matchStart, matchEnd, name = string.find(source, "export%s+type%s+([%w_]+)", pos)
		if matchStart == nil or matchEnd == nil or name == nil then
			break
		end
		local nameEnd = matchEnd :: number
		pos = nameEnd + 1

		if matchStart > 1 and isWordChar(string.sub(source, matchStart - 1, matchStart - 1)) then
			continue
		end

		if name == "function" then
			continue
		end

		local scan = nameEnd + 1
		while scan <= len and string.sub(source, scan, scan):match("%s") do
			scan += 1
		end

		local lhsGenerics = ""
		local rhsGenerics = ""
		if string.sub(source, scan, scan) == "<" then
			local depth = 1
			local endAngle = scan + 1
			while endAngle <= len and depth > 0 do
				local c = string.sub(source, endAngle, endAngle)
				if c == "<" then
					depth += 1
				elseif c == ">" then
					depth -= 1
				end
				if depth > 0 then
					endAngle += 1
				end
			end
			if depth ~= 0 then
				continue
			end
			local inside = string.sub(source, scan + 1, endAngle - 1)
			lhsGenerics = `<{inside}>`
			local rhsNames: { string } = {}
			for _, param in splitTopLevelCommas(inside) do
				table.insert(rhsNames, stripDefault(param))
			end
			rhsGenerics = `<{table.concat(rhsNames, ", ")}>`
			scan = endAngle + 1
		end

		while scan <= len and string.sub(source, scan, scan):match("%s") do
			scan += 1
		end
		if string.sub(source, scan, scan) ~= "=" then
			continue
		end

		table.insert(exports, `export type {name}{lhsGenerics} = module.{name}{rhsGenerics}`)
	end

	return exports
end

return extractExports
