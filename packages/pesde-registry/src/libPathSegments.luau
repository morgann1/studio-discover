--!strict

-- The Instance path from a package's root to its library module. A trailing `init` file is the folder itself.
const function libPathSegments(libPath: string?): { string }
	if libPath == nil or libPath == "" then
		return {}
	end

	const parts = string.split(libPath, "/")
	const leaf = parts[#parts]
	if leaf == "init.luau" or leaf == "init.lua" then
		table.remove(parts)
	else
		parts[#parts] = (leaf:gsub("%.luau?$", ""))
	end

	const segments: { string } = {}
	for _, part in parts do
		if part ~= "" and part ~= "." then
			table.insert(segments, part)
		end
	end

	return segments
end

return libPathSegments
