--[[
	Release Notes Entry Point

	Extracts the CHANGELOG.md section for a given tag and prints it to stdout.
]]

local process = require("@lute/process")

local cli = require("./lib/cli/parser")
local command = require("./commands/release-notes")

local function main()
	local parser = cli.parser()
	parser:setDescription(command.description)
	parser:setCommandName(`lute run {command.name}`)

	for _, arg: any in command.arguments do
		parser:add(arg.name, arg.kind, arg.options)
	end

	parser:parse(process.args)

	command.run({
		tag = parser:get("tag") :: string?,
	})
end

main()
