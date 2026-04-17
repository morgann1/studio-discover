--[[
	Deploy Entry Point

	Deploys the Cloudflare Worker in backend/.
]]

local process = require("@lune/process")

local cli = require("./lib/cli/parser")
local command = require("./commands/deploy")

local function main()
	local parser = cli.parser()
	parser:setDescription(command.description)
	parser:setCommandName(`lune run {command.name}`)

	parser:parse(process.args)

	command.run()
end

main()
