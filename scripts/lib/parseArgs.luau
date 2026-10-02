--!strict

--[[
	Reads the command-line arguments for the scripts.

	Lute puts the script path in `process.args[1]`, so it is always skipped.

	Pass the names of switches that consume the following argument as their
		value. Everything else starting with `-` is a boolean flag, and everything
		else is positional, which is what keeps the path in
		`upload-plugin --tag v1.0.0 build.rbxm` out of the values table.

	Aliases are deliberately not modelled. A command wanting `-f` alongside
		`--fix` reads `args.flags.fix or args.flags.f`, which is cheaper than a
		declaration for the few commands that have one.
]]

const process = require("@lute/process")

export type Args = {
	read flags: { [string]: boolean? },
	read values: { [string]: string? },
	read positionals: { string },
}

const function parseArgs(valued: { string }?): Args
	const takesValue: { [string]: boolean? } = {}
	if valued ~= nil then
		for _, name in valued do
			takesValue[name] = true
		end
	end

	const args: Args = { flags = {}, values = {}, positionals = {} }
	const argv = process.args

	local i = 2
	while i <= #argv do
		const token = argv[i]

		if string.sub(token, 1, 1) ~= "-" then
			table.insert(args.positionals, token)
		else
			const inlineName, inlineValue = string.match(token, "^%-%-?([^=]+)=(.*)$")
			if inlineName ~= nil and inlineValue ~= nil then
				args.values[inlineName] = inlineValue
			else
				const name = string.gsub(token, "^%-%-?", "")
				if takesValue[name] == true and argv[i + 1] ~= nil then
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

return parseArgs
