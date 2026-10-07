--!strict

--[[
	Regenerates the names Nevermore packages go by in the plugin.

	Usage: lute scripts/nevermore-names.luau

	npm names are lowercase, like "characterutils", and npm records no other name.
		The name people know is the module they require, like "CharacterUtils", so
		this reads the module names out of the NevermoreEngine source tree and works
		out each package's name from them:

	1. A module named like the package, ignoring case and dashes.
	2. A module that starts with the package's name at a word break, like
		"BinarySearch" from "BinarySearchUtils".
	3. The package's name split into words seen in module names and npm
		descriptions, like "FirstPersonCharacterTransparency".

	Packages none of these name, and the quentystudios forks, which live outside
		NevermoreEngine, come from `OVERRIDES`. Run it again when Quenty publishes new
		packages, and commit the result.
]]

const fs = require("@std/fs")
const json = require("@std/json")

const fetchAsync = require("@scripts/lib/fetchAsync")
const readJsonField = require("@scripts/lib/readJsonField")

const OUTPUT = "packages/nevermore-registry/src/knownNames.luau"
const TREE_URL = "https://api.github.com/repos/Quenty/NevermoreEngine/git/trees/main?recursive=1"
const SEARCH_URL = "https://registry.npmjs.org/-/v1/search?text=maintainer:quenty&size=250"

-- Names the rules get wrong or can't find, keyed by npm name without the scope.
const OVERRIDES: { [string]: string } = {
	cmdr = "Cmdr",
	["jest-lua"] = "JestLua",
	memoize = "Memoize",
	ugcsanitize = "UGCSanitize",
}

-- Splits "ArmIKBase" into "Arm", "IK", "Base", and "Motor6D" into "Motor", "6", "D".
const function splitWords(name: string): { string }
	const words: { string } = {}
	local current = ""

	for i = 1, #name do
		const char = string.sub(name, i, i)
		const previous = string.sub(name, i - 1, i - 1)
		const following = string.sub(name, i + 1, i + 1)

		const isUpper = string.match(char, "%u") ~= nil
		const isDigit = string.match(char, "%d") ~= nil
		const wasDigit = string.match(previous, "%d") ~= nil
		const startsWord = (isUpper and string.match(previous, "%l") ~= nil)
			or (isUpper and string.match(previous, "%u") ~= nil and string.match(following, "%l") ~= nil)
			or (isDigit ~= wasDigit and previous ~= "")

		if startsWord and current ~= "" then
			table.insert(words, current)
			current = ""
		end
		current ..= char
	end

	if current ~= "" then
		table.insert(words, current)
	end

	return words
end

-- Every module name under each package's `src`, keyed by the package's folder in NevermoreEngine.
const function readModules(tree: json.Value): { [string]: { string } }
	const modules: { [string]: { string } } = {}

	const entries = readJsonField(tree, "tree")
	if typeof(entries) ~= "table" then
		error("NevermoreEngine tree has no entries", 0)
	end

	for _, entry in entries :: json.Array do
		const path = readJsonField(entry, "path")
		if typeof(path) ~= "string" then
			continue
		end

		const folder, rest = string.match(path, "^src/([^/]+)/src/(.+)$")
		if folder == nil or rest == nil then
			continue
		end

		const name = string.match(rest, "([^/]+)/init%.luau?$") or string.match(rest, "([^/]+)%.luau?$")
		if name == nil or string.match(name, "^%w+$") == nil then
			continue
		end

		const list = modules[folder] or {}
		table.insert(list, name)
		modules[folder] = list
	end

	for _, list in modules do
		table.sort(list)
	end

	return modules
end

type Package = {
	read name: string,
	read description: string,
}

-- Every @quenty package for Roblox, the way the plugin's catalog picks them.
const function readPackagesAsync(): { Package }
	const packages: { Package } = {}
	local from = 0

	while true do
		const response = json.deserialize(fetchAsync(`{SEARCH_URL}&from={from}`).body)
		const objects = readJsonField(response, "objects")
		if typeof(objects) ~= "table" then
			error("npm search response has no objects", 0)
		end

		local count = 0
		for _, object in objects :: json.Array do
			count += 1

			const package = readJsonField(object, "package")
			const fullName = readJsonField(package, "name")
			const keywords = readJsonField(package, "keywords")
			const description = readJsonField(package, "description")
			const name = if typeof(fullName) == "string" then string.match(fullName, "^@quenty/(.+)$") else nil
			if name == nil or typeof(keywords) ~= "table" then
				continue
			end

			local isRoblox = false
			for _, keyword in keywords :: json.Array do
				if typeof(keyword) == "string" and string.lower(keyword) == "lua" then
					isRoblox = true
				end
			end

			if isRoblox then
				table.insert(packages, {
					name = name,
					description = if typeof(description) == "string" then description else "",
				})
			end
		end

		from += 250
		if count < 250 then
			return packages
		end
	end
end

--[[
	The words names are built from, keyed by their lowercase spelling. Module names
		win over descriptions, and the most common spelling wins among module names.
		Single letters are left out, since they split words like "Sprites" wrongly.
]]
const function buildVocabulary(modules: { [string]: { string } }, packages: { Package }): { [string]: string }
	const counts: { [string]: number } = {}
	for _, list in modules do
		for _, module in list do
			for _, word in splitWords(module) do
				if #word > 1 then
					counts[word] = (counts[word] or 0) + 1
				end
			end
		end
	end

	const vocabulary: { [string]: string } = {}
	for word, count in counts do
		const key = string.lower(word)
		const existing = vocabulary[key]
		if existing == nil or count > counts[existing] or (count == counts[existing] and word < existing) then
			vocabulary[key] = word
		end
	end

	for _, package in packages do
		for word in string.gmatch(package.description, "%a+") do
			const key = string.lower(word)
			if #word > 1 and vocabulary[key] == nil then
				vocabulary[key] = if string.match(word, "^%u+$") ~= nil
					then word
					else string.upper(string.sub(word, 1, 1)) .. string.lower(string.sub(word, 2))
			end
		end
	end

	return vocabulary
end

-- Splits `text` into the fewest vocabulary words, or returns nil when it can't.
const function segment(text: string, vocabulary: { [string]: string }): { string }?
	const best: { [number]: { string } } = { [0] = {} }

	for i = 1, #text do
		for j = math.max(0, i - 30), i - 1 do
			const before = best[j]
			const word = vocabulary[string.sub(text, j + 1, i)]
			if before ~= nil and word ~= nil and (best[i] == nil or #before + 1 < #best[i]) then
				const words = table.clone(before)
				table.insert(words, word)
				best[i] = words
			end
		end
	end

	return best[#text]
end

-- One dash-separated part of a name as words, trying it as a plural when it doesn't split as is.
const function segmentPart(part: string, vocabulary: { [string]: string }): { string }?
	const words = segment(part, vocabulary)
	if words ~= nil or string.sub(part, -1) ~= "s" then
		return words
	end

	const singular = segment(string.sub(part, 1, -2), vocabulary)
	if singular == nil then
		return nil
	end

	singular[#singular] ..= "s"
	return singular
end

const function nameOf(package: string, modules: { string }, vocabulary: { [string]: string }): string?
	const key = (string.gsub(package, "%-", ""))

	for _, module in modules do
		if string.lower(module) == key then
			return module
		end
	end

	const byLength = table.clone(modules)
	table.sort(byLength, function(a: string, b: string)
		return #a < #b or (#a == #b and a < b)
	end)
	for _, module in byLength do
		const following = string.sub(module, #key + 1, #key + 1)
		if string.lower(string.sub(module, 1, #key)) == key and string.match(following, "[%u%d]") ~= nil then
			return string.sub(module, 1, #key)
		end
	end

	local name = ""
	for part in string.gmatch(package, "[^-]+") do
		const words = segmentPart(part, vocabulary)
		if words == nil then
			return nil
		end

		for _, word in words do
			name ..= string.upper(string.sub(word, 1, 1)) .. string.sub(word, 2)
		end
	end

	return name
end

const function render(names: { [string]: string }): string
	const keys: { string } = {}
	for key in names do
		table.insert(keys, key)
	end
	table.sort(keys)

	const lines = {
		"--!strict",
		"",
		"--[[",
		"\tThe names Nevermore packages go by, keyed by npm name without the scope, such as",
		'\t\t"characterutils" for "CharacterUtils". npm only has the lowercase name.',
		"",
		"\tGenerated by `lute scripts/nevermore-names.luau`. Change its overrides, not this file.",
		"]]",
		"",
		"const knownNames: { [string]: string } = {",
	}
	for _, key in keys do
		table.insert(lines, `\t["{key}"] = "{names[key]}",`)
	end
	table.insert(lines, "}")
	table.insert(lines, "")
	table.insert(lines, "return table.freeze(knownNames)")
	table.insert(lines, "")

	return table.concat(lines, "\n")
end

const modules = readModules(json.deserialize(fetchAsync(TREE_URL).body))
const packages = readPackagesAsync()
const vocabulary = buildVocabulary(modules, packages)

const names: { [string]: string } = {}
const unnamed: { string } = {}
for _, package in packages do
	const name = nameOf(package.name, modules[package.name] or {}, vocabulary)
	if name ~= nil then
		names[package.name] = name
	elseif OVERRIDES[package.name] == nil then
		table.insert(unnamed, package.name)
	end
end

for key, name in OVERRIDES do
	names[key] = name
end

fs.writeStringToFile(OUTPUT, render(names))
print(`wrote {OUTPUT}`)

if #unnamed > 0 then
	table.sort(unnamed)
	print(`no name for {#unnamed} package(s), which keep their npm name: {table.concat(unnamed, ", ")}`)
end
