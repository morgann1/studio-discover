--!strict

--[[
	The upstream repos `scripts/sync.luau` clones into `.repos/`.

	Discover's packages are Luau ports of these tools, so having the real
		implementation on disk at the version we target is what makes "does wally
		actually do it this way" a question you can answer instead of guess.

	`versionSource` names a rokit.toml tool entry, e.g. `wally =
		"UpliftGames/wally@0.3.2"`, and the ref becomes `tagPrefix .. version`. Leave
		it out for a repo we do not depend on at a specific version, and the sync
		follows `latestRef` instead.
]]

export type VersionSource = {
	-- File to read the version out of, relative to the repo root.
	read path: string,
	-- The rokit.toml `[tools]` key whose pinned version we want.
	read tool: string,
	-- Prepended to the resolved version to form the tag, e.g. "v" .. "0.3.2".
	read tagPrefix: string,
}

export type ReferenceRepo = {
	read id: string,
	-- Directory the checkout lands in, relative to the repo root. Gitignored.
	read prefix: string,
	read repository: string,
	-- Branch used by --latest.
	read latestRef: string,
	read versionSource: VersionSource?,
}

const referenceRepos: { ReferenceRepo } = {
	{
		id = "wally",
		prefix = ".repos/wally",
		repository = "https://github.com/UpliftGames/wally.git",
		latestRef = "main",
		versionSource = { path = "rokit.toml", tool = "wally", tagPrefix = "v" },
	},
	{
		id = "wally-package-types",
		prefix = ".repos/wally-package-types",
		repository = "https://github.com/JohnnyMorganz/wally-package-types.git",
		latestRef = "main",
		versionSource = { path = "rokit.toml", tool = "wally-package-types", tagPrefix = "v" },
	},
	{
		-- pesde is not a rokit tool, so nothing here pins a version to read.
		id = "pesde",
		prefix = ".repos/pesde",
		repository = "https://github.com/pesde-pkg/pesde.git",
		latestRef = "main",
		versionSource = nil,
	},

	--[[
		Peer Studio plugins, kept for how they solve the problems we also have:
			widget chrome, Foundation usage, build tooling and release workflow.
	]]
	{
		id = "studio-activity",
		prefix = ".repos/studio-activity",
		repository = "https://github.com/BrookenRecord/studio-activity.git",
		latestRef = "main",
		versionSource = nil,
	},
	{
		id = "flipbook",
		prefix = ".repos/flipbook",
		repository = "https://github.com/flipbook-labs/flipbook.git",
		latestRef = "main",
		versionSource = nil,
	},
}

table.freeze(referenceRepos)

return referenceRepos
