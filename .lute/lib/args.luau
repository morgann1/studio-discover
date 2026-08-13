--[[
	Argument reading for the dev CLI.

	`process.args[1]` is the command name itself, so it is always skipped.

	Pass the names of switches that consume the following argument as their
	value. Everything else starting with `-` is a boolean flag, and everything
	else is positional, which is what keeps the path in
	`upload-plugin --tag v1.0.0 build.rbxm` out of the values table.

	Aliases are deliberately not modelled. A command wanting `-f` alongside
	`--fix` reads `args.flags.fix or args.flags.f`, which is cheaper than a
	declaration for the three commands that have one.
]]

local process = require("@lute/process")

export type Args = {
	flags: { [string]: boolean },
	values: { [string]: string },
	positionals: { string },
}

local function parse(valued: { string }?): Args
	local takesValue: { [string]: boolean } = {}
	if valued ~= nil then
		for _, name in valued do
			takesValue[name] = true
		end
	end

	local args: Args = { flags = {}, values = {}, positionals = {} }
	local argv = process.args

	local i = 2
	while i <= #argv do
		local token = argv[i]

		if string.sub(token, 1, 1) ~= "-" then
			table.insert(args.positionals, token)
		else
			local inlineName, inlineValue = string.match(token, "^%-%-?([^=]+)=(.*)$")
			if inlineName ~= nil and inlineValue ~= nil then
				args.values[inlineName] = inlineValue
			else
				local name = string.gsub(token, "^%-%-?", "")
				if takesValue[name] and argv[i + 1] ~= nil then
					args.values[name] = argv[i + 1]
					i += 1
				else
					args.flags[name] = true
				end
			end
		end

		i += 1
	end

	return args
end

return parse
