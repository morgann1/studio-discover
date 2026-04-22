--[[
	Release Notes Command

	Reads CHANGELOG.md and prints the section for the requested tag so the
	release workflow can feed it straight into the GitHub release body.
]]

local fs = require("@lute/fs")
local process = require("@lute/process")

local releaseNotes = {}

releaseNotes.name = "release-notes"
releaseNotes.description = "Prints the CHANGELOG.md section for a given tag"
releaseNotes.usage = "lute run release-notes --tag vX.Y.Z"

releaseNotes.arguments = {
	{
		name = "tag",
		kind = "option",
		options = {
			help = "Release tag, with or without a leading `v`",
			aliases = { "t" },
			required = true,
		},
	},
}

export type Options = {
	tag: string?,
}

local FALLBACK = "See [CHANGELOG.md](./CHANGELOG.md) for details."

local function stripLeadingV(tag: string): string
	local stripped = string.match(tag, "^v(.+)$")
	return stripped or tag
end

-- Captures lines between `## [<version>]` (exclusive) and the next `## [`
-- (exclusive), trimming surrounding blank lines from the result.
local function extractSection(changelog: string, version: string): string?
	local header = `## [{version}]`
	local lines = string.split(changelog, "\n")

	local body: { string } = {}
	local capturing = false
	for _, line in lines do
		if capturing then
			if string.sub(line, 1, 4) == "## [" then
				break
			end
			table.insert(body, line)
		elseif string.sub(line, 1, #header) == header then
			capturing = true
		end
	end

	if #body == 0 then
		return nil
	end

	while #body > 0 and string.match(body[1], "^%s*$") ~= nil do
		table.remove(body, 1)
	end
	while #body > 0 and string.match(body[#body], "^%s*$") ~= nil do
		table.remove(body)
	end

	if #body == 0 then
		return nil
	end

	return table.concat(body, "\n")
end

function releaseNotes.run(options_: Options?)
	local options: Options = options_ or {}
	local tag = options.tag
	if tag == nil or tag == "" then
		print("release-notes: missing --tag argument")
		process.exit(1)
		return
	end

	local version = stripLeadingV(tag)
	local handle = fs.open("CHANGELOG.md", "r")
	local changelog = fs.read(handle)
	fs.close(handle)
	local section = extractSection(changelog, version)

	if section == nil then
		print(FALLBACK)
		return
	end

	print(section)
end

return releaseNotes
