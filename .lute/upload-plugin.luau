--[[
	Upload Plugin Entry Point

	Publishes a built .rbxm as a new Creator Store plugin version via the
	Open Cloud Luau Execution Task API.
]]

local process = require("@lute/process")

local cli = require("./lib/cli/parser")
local command = require("./commands/upload-plugin")

local function main()
	local parser = cli.parser()
	parser:setDescription(command.description)
	parser:setCommandName(`lute run {command.name}`)

	for _, arg: any in command.arguments do
		parser:add(arg.name, arg.kind, arg.options)
	end

	local args = { table.unpack(process.args, 2) }
	parser:parse(args)

	local path = parser:get("path") :: string?
	assert(path, "missing required argument: path")

	command.run({
		path = path,
		tag = parser:get("tag") :: string?,
	})
end

main()
