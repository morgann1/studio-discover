--[[
	Rojo Operations

	Provides common Rojo-related operations used across multiple commands.
]]

local process = require("@lute/process")

local rojo = {}

export type BuildOptions = {
	projectFile: string?,
	output: string?,
	plugin: string?,
	quiet: boolean?,
	watch: boolean?,
	stdio: process.StdioKind?,
}

export type BuildResult = {
	ok: boolean,
	code: number,
	stderr: string?,
}

--[[
	Builds a Rojo project to a place file.

	@param options Build options
	@return Build result with success status and any error info
]]
function rojo.build(options: BuildOptions): BuildResult
	local args = { "rojo", "build" }

	if options.projectFile then
		table.insert(args, options.projectFile)
	end

	if options.output then
		table.insert(args, "--output")
		table.insert(args, options.output)
	end

	if options.plugin then
		table.insert(args, "--plugin")
		table.insert(args, options.plugin)
	end

	if options.watch then
		table.insert(args, "--watch")
	end

	local result = process.run(args, {
		stdio = options.stdio,
	})

	return {
		ok = result.ok,
		code = result.exitcode,
		stderr = if result.ok then nil else result.stderr,
	}
end

export type ServeOptions = {
	projectFile: string,
}

--[[
	Starts a Rojo serve session.

	@param options Serve options
	@return Serve result with success status and exit code
]]
function rojo.serve(options: ServeOptions): BuildResult
	local result = process.run({
		"rojo",
		"serve",
		options.projectFile,
	}, {
		stdio = "inherit",
	})

	return {
		ok = result.ok,
		code = result.exitcode,
		stderr = if result.ok then nil else result.stderr,
	}
end

export type SourcemapOptions = {
	projectFile: string?,
	output: string?,
	includeNonScripts: boolean?,
	absolute: boolean?,
}

--[[
	Generates a Rojo sourcemap.

	@param options Sourcemap options
	@return success, error message
]]
function rojo.sourcemap(options_: SourcemapOptions?): (boolean, string)
	local options: SourcemapOptions = options_ or {}
	local projectFile = if options.projectFile ~= nil then options.projectFile else "default.project.jsonc"
	local output = if options.output ~= nil then options.output else "sourcemap.json"
	local includeNonScripts = if options.includeNonScripts ~= nil then options.includeNonScripts else true
	local absolute = if options.absolute ~= nil then options.absolute else true

	local args = {
		"rojo",
		"sourcemap",
		projectFile,
		"--output",
		output,
	}

	if includeNonScripts then
		table.insert(args, "--include-non-scripts")
	end

	if absolute then
		table.insert(args, "--absolute")
	end

	local result = process.run(args)
	if not result.ok then
		return false, result.stderr
	end

	return true, result.stdout
end

return rojo
