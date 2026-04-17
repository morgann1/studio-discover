--[[
	Deploy Command

	Deploys the Cloudflare Worker in backend/ via wrangler.
]]

local process = require("@lune/process")

local color = require("../utils/color")

local deploy = {}

-- Metadata for help command
deploy.name = "deploy"
deploy.description = "Deploys the Cloudflare Worker in backend/"
deploy.usage = "lune run deploy"

-- Argument definitions for CLI parsing
deploy.arguments = {}

export type Options = {}

--[[
	Runs `wrangler deploy` inside backend/.
]]
function deploy.run(_options: Options?)
	print(color.bold(color.white("Deploying backend...\n")))

	local result = process.exec("npx", { "wrangler", "deploy" }, {
		stdio = "inherit",
		shell = true,
		cwd = "backend",
	})

	if result.ok then
		print()
		print(color.bold(color.green("Deploy succeeded")))
	else
		print()
		print(color.bold(color.red("Deploy failed")))
		process.exit(1)
	end
end

return deploy
