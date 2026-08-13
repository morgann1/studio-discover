--[[
	Vendors the upstream reference repos into `.repos/` with git subtree.

	Usage: lute run sync [--repo <id>] [--latest] [--dry-run]

	Each repo is added the first time and pulled afterwards, pinned to the tag
	matching the version this repo targets, or following its branch when we do
	not depend on a particular version. `--latest` ignores the pins and takes
	every branch tip, and `--dry-run` prints the git commands without running
	them.

	git subtree commits the vendored content into this repository, which is what
	makes the reference reproducible for everyone who clones it, and also what
	makes the first sync a large commit. Run it deliberately.

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
	args: { string },
}

local function isDir(path: string): boolean
	return fs.exists(path) and fs.type(path) == "dir"
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

local function planFor(repo: ReferenceRepo, latest: boolean): (Plan?, string?)
	local ref, reason = resolveRef(repo, latest)
	if ref == nil then
		return nil, reason
	end

	local action = if isDir(repo.prefix) then "pull" else "add"

	return {
		repo = repo,
		action = action,
		ref = ref,
		args = { "subtree", action, `--prefix={repo.prefix}`, repo.repository, ref, "--squash" },
	},
		nil
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

-- git subtree refuses to work from a dirty tree, with a message that does not
-- make the reason obvious. Say it plainly instead.
local function requireCleanTree()
	local result = process.run({ "git", "status", "--porcelain" })
	if not result.ok then
		print(color.bold(color.red("Could not read git status")))
		process.exit(1)
		return
	end
	if result.stdout:match("%S") ~= nil then
		print(
			color.bold(color.red("Working tree is not clean. git subtree needs a clean tree; commit or stash first."))
		)
		process.exit(1)
	end
end

local args = parseArgs({ "repo" })
local latest = args.flags.latest or false
local dryRun = args.flags["dry-run"] or false
local repos = selectRepos(args.values.repo)

print(color.bold(color.white(if dryRun then "Planning reference repo sync...\n" else "Syncing reference repos...\n")))

if not dryRun then
	requireCleanTree()
end

local failed = false

for _, repo in repos do
	local plan, reason = planFor(repo, latest)
	if plan == nil then
		print(color.red(`  ✗ {reason}`))
		failed = true
		continue
	end

	print(color.cyan(`→ {repo.id}: git subtree {plan.action} from {plan.ref}`))

	if dryRun then
		print(color.dim(`  git {table.concat(plan.args, " ")}`))
		continue
	end

	local result = process.run({ "git", table.unpack(plan.args) }, { stdio = "inherit" })
	if result.ok then
		print(color.green(`  ✓ {repo.prefix}`))
	else
		print(color.red(`  ✗ git subtree {plan.action} failed for "{repo.id}"`))
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
