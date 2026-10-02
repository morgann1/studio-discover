--!strict

--[[
	Clones the reference repos into `.repos/`.

	Usage: lute scripts/sync.luau [--repo <id>] [--latest] [--dry-run]

	Each repo is cloned shallow the first time and fetched afterwards, pinned to
		the tag matching the version this repo targets, or following its branch when
		we do not depend on a particular version. `--latest` ignores the pins and
		takes every branch tip, and `--dry-run` prints the git commands without
		running them.

	`.repos/` is gitignored. These are local reading material, not vendored
		dependencies, so nothing here is committed and nothing here is built. Run it
		again whenever you bump a matching dependency.

	The repos themselves are declared in lib/referenceRepos.
]]

const fs = require("@std/fs")
const process = require("@lute/process")

const color = require("@scripts/lib/color")
const parseArgs = require("@scripts/lib/parseArgs")
const referenceRepos = require("@scripts/lib/referenceRepos")

type ReferenceRepo = referenceRepos.ReferenceRepo

type Result<T> = { read ok: true, read value: T } | { read ok: false, read reason: string }

type Plan = {
	read action: "clone" | "update",
	read ref: string,
	read commands: { { string } },
}

const function isDirAsync(path: string): boolean
	return fs.exists(path) and fs.type(path) == "dir"
end

--[[
	Only a directory with a .git in it can be fetched into. Anything else there is
		something we did not create, and clobbering it is not our call.
]]
const function isCloneAsync(path: string): boolean
	return isDirAsync(path) and fs.exists(`{path}/.git`)
end

-- Lua patterns treat `-` as a quantifier, and tool names contain it.
const function escapePattern(text: string): string
	return (string.gsub(text, "([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1"))
end

--[[
	Reads a rokit `[tools]` version, given `wally = "UpliftGames/wally@0.3.2"`
		returns "0.3.2". Returns nil when the file or the entry is missing.
]]
const function readToolVersionAsync(sourcePath: string, tool: string): string?
	if not fs.exists(sourcePath) then
		return nil
	end

	const contents = fs.readFileToString(sourcePath)
	return (string.match(contents, `%f[%w_]{escapePattern(tool)}%s*=%s*"[^"@]+@([^"]+)"`))
end

--[[
	Returns the ref to sync, or the reason it cannot be resolved.

	A repo with no versionSource tracks its branch, because not depending on a
		specific version is a choice rather than a failure. Only a version that was
		declared and then could not be read is an error.
]]
const function resolveRefAsync(repo: ReferenceRepo, latest: boolean): Result<string>
	const source = repo.versionSource
	if latest or source == nil then
		return { ok = true, value = repo.latestRef }
	end

	const version = readToolVersionAsync(source.path, source.tool)
	if version == nil then
		return { ok = false, reason = `could not read a version for "{source.tool}" from {source.path}` }
	end

	return { ok = true, value = `{source.tagPrefix}{version}` }
end

--[[
	A fresh checkout is one shallow clone. An existing one is a shallow fetch of
		the wanted ref followed by a hard reset onto it, which moves between tags and
		branches without keeping any history we would never read.
]]
const function planForAsync(repo: ReferenceRepo, latest: boolean): Result<Plan>
	const resolved = resolveRefAsync(repo, latest)
	if not resolved.ok then
		return resolved
	end

	const ref = resolved.value

	if isCloneAsync(repo.prefix) then
		return {
			ok = true,
			value = {
				action = "update",
				ref = ref,
				commands = {
					{ "git", "-C", repo.prefix, "fetch", "--depth", "1", "origin", ref },
					{ "git", "-C", repo.prefix, "reset", "--hard", "FETCH_HEAD" },
				},
			},
		}
	end

	if isDirAsync(repo.prefix) then
		return { ok = false, reason = `{repo.prefix} exists but is not a git checkout. Remove it and sync again.` }
	end

	return {
		ok = true,
		value = {
			action = "clone",
			ref = ref,
			commands = {
				{ "git", "clone", "--depth", "1", "--branch", ref, repo.repository, repo.prefix },
			},
		},
	}
end

-- Runs each command in order with its output streamed, and stops at the first failure.
const function runCommandsAsync(commands: { { string } }): boolean
	for _, command in commands do
		if not process.run(command, { stdio = "inherit" }).ok then
			return false
		end
	end

	return true
end

const function selectRepos(repoId: string?): { ReferenceRepo }
	if repoId == nil then
		return referenceRepos
	end

	for _, repo in referenceRepos do
		if repo.id == repoId then
			return { repo }
		end
	end

	const known: { string } = {}
	for _, repo in referenceRepos do
		table.insert(known, repo.id)
	end

	print(color.bold(color.red(`Unknown repo "{repoId}". Known: {table.concat(known, ", ")}`)))
	process.exit(1)

	-- `process.exit` never returns, but the type checker still wants a value on this path.
	return {}
end

const args = parseArgs({ "repo" })
const latest = args.flags.latest or false
const dryRun = args.flags["dry-run"] or false
const repos = selectRepos(args.values.repo)

print(color.bold(color.white(if dryRun then "Planning reference repo sync...\n" else "Syncing reference repos...\n")))

local failed = false

for _, repo in repos do
	const planned = planForAsync(repo, latest)
	if not planned.ok then
		print(color.red(`  ✗ {planned.reason}`))
		failed = true
		continue
	end

	const plan = planned.value
	print(color.cyan(`→ {repo.id}: {plan.action} at {plan.ref}`))

	if dryRun then
		for _, command in plan.commands do
			print(color.dim(`  {table.concat(command, " ")}`))
		end
		continue
	end

	if runCommandsAsync(plan.commands) then
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
