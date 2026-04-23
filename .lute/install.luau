--[[
	Install Entry Point
	
	Installs all packages.
]]

local process = require("@lute/process")

local cli = require("./lib/cli/parser")
local command = require("./commands/install")

local function main()
	local parser = cli.parser()
	parser:setDescription(command.description)
	parser:setCommandName(`lute run {command.name}`)

	for _, arg: any in command.arguments do
		parser:add(arg.name, arg.kind, arg.options)
	end

	parser:parse(process.args)

	local ok = command.run({
		quiet = parser:has("quiet"),
	})
	if not ok then
		process.exit(1)
	end
end

main()
