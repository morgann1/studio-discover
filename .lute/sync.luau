--[[
	Clones the reference repos into `.repos/`.

	Usage: lute run sync [--repo <id>] [--latest] [--dry-run]

	Each repo is cloned shallow the first time and fetched afterwards, pinned to
	the tag matching the version this repo targets, or following its branch when
	we do not depend on a particular version. `--latest` ignores the pins and
	takes every branch tip, and `--dry-run` prints the git commands without
	running them.

	`.repos/` is gitignored. These are local reading material, not vendored
	dependencies, so nothing here is committed and nothing here is built. Run it
	again whenever you bump a matching dependency.

	The repos themselves are declared in lib/reference-repos.
]]

local fs = require("@lute/fs")
local process = require("@lute/process")

local color = require("./lib/color")
local parseArgs = require("./lib/args")
local referenceRepos = require("./lib/reference-repos")

type ReferenceRepo = referenceRepos.ReferenceRepo

type Plan = {
	repo: ReferenceRepo,
	action: string,
	ref: string,
	commands: { { string } },
}

local function isDir(path: string): boolean
	return fs.exists(path) and fs.type(path) == "dir"
end

-- Only a directory with a .git in it can be fetched into. Anything else there is
-- something we did not create, and clobbering it is not our call.
local function isClone(path: string): boolean
	return isDir(path) and fs.exists(`{path}/.git`)
end

-- Lua patterns treat `-` as a quantifier, and tool names contain it.
local function escapePattern(text: string): string
	return (text:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1"))
end

--[[
	Reads a rokit `[tools]` version, given `wally = "UpliftGames/wally@0.3.2"`
	returns "0.3.2". Returns nil when the file or the entry is missing.
]]
local function readToolVersion(sourcePath: string, tool: string): string?
	if not fs.exists(sourcePath) then
		return nil
	end

	local handle = fs.open(sourcePath, "r")
	local contents = fs.read(handle)
	fs.close(handle)

	return contents:match(`%f[%w_]{escapePattern(tool)}%s*=%s*"[^"@]+@([^"]+)"`)
end

--[[
	Returns the ref to sync, or nil with a reason when it cannot be resolved.

	A repo with no versionSource tracks its branch, because not depending on a
	specific version is a choice rather than a failure. Only a version that was
	declared and then could not be read is an error.
]]
local function resolveRef(repo: ReferenceRepo, latest: boolean): (string?, string?)
	local source = repo.versionSource
	if latest or source == nil then
		return repo.latestRef, nil
	end

	local version = readToolVersion(source.path, source.tool)
	if version == nil then
		return nil, `could not read a version for "{source.tool}" from {source.path}`
	end

	return `{repo.tagPrefix}{version}`, nil
end

--[[
	A fresh checkout is one shallow clone. An existing one is a shallow fetch of
	the wanted ref followed by a hard reset onto it, which moves between tags and
	branches without keeping any history we would never read.
]]
local function planFor(repo: ReferenceRepo, latest: boolean): (Plan?, string?)
	local ref, reason = resolveRef(repo, latest)
	if ref == nil then
		return nil, reason
	end

	local commands: { { string } }
	local action: string

	if isClone(repo.prefix) then
		action = "update"
		commands = {
			{ "git", "-C", repo.prefix, "fetch", "--depth", "1", "origin", ref },
			{ "git", "-C", repo.prefix, "reset", "--hard", "FETCH_HEAD" },
		}
	elseif isDir(repo.prefix) then
		return nil, `{repo.prefix} exists but is not a git checkout. Remove it and sync again.`
	else
		action = "clone"
		commands = {
			{ "git", "clone", "--depth", "1", "--branch", ref, repo.repository, repo.prefix },
		}
	end

	return { repo = repo, action = action, ref = ref, commands = commands }, nil
end

local function selectRepos(repoId: string?): { ReferenceRepo }
	if repoId == nil then
		return referenceRepos
	end

	for _, repo in referenceRepos do
		if repo.id == repoId then
			return { repo }
		end
	end

	local known: { string } = {}
	for _, repo in referenceRepos do
		table.insert(known, repo.id)
	end
	print(color.bold(color.red(`Unknown repo "{repoId}". Known: {table.concat(known, ", ")}`)))
	process.exit(1)
	return {}
end

local args = parseArgs({ "repo" })
local latest = args.flags.latest or false
local dryRun = args.flags["dry-run"] or false
local repos = selectRepos(args.values.repo)

print(color.bold(color.white(if dryRun then "Planning reference repo sync...\n" else "Syncing reference repos...\n")))

local failed = false

for _, repo in repos do
	local plan, reason = planFor(repo, latest)
	if plan == nil then
		print(color.red(`  ✗ {reason}`))
		failed = true
		continue
	end

	print(color.cyan(`→ {repo.id}: {plan.action} at {plan.ref}`))

	if dryRun then
		for _, command in plan.commands do
			print(color.dim(`  {table.concat(command, " ")}`))
		end
		continue
	end

	local ok = true
	for _, command in plan.commands do
		local result = process.run(command, { stdio = "inherit" })
		if not result.ok then
			ok = false
			break
		end
	end

	if ok then
		print(color.green(`  ✓ {repo.prefix}`))
	else
		print(color.red(`  ✗ {plan.action} failed for "{repo.id}"`))
		failed = true
	end
end

print()
if failed then
	print(color.bold(color.red("Some repos did not sync.")))
	process.exit(1)
else
	print(color.bold(color.green(if dryRun then "Plan complete." else "Reference repos synced.")))
end
