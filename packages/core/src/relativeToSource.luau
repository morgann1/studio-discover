--!strict

--[[
	Maps an archive path to its place in the package, given the project's source path
		from `readProjectSourcePath`. Returns nil when the path falls outside it. A
		source path that is a single file becomes the package's init file.
]]
const function relativeToSource(path: string, sourcePath: string?): string?
	if sourcePath == nil or path == sourcePath then
		return path
	elseif string.sub(path, 1, #sourcePath + 1) == `{sourcePath}/` then
		return string.sub(path, #sourcePath + 2)
	elseif path == `{sourcePath}.luau` or path == `{sourcePath}.lua` then
		return "init.luau"
	end

	return nil
end

return relativeToSource
