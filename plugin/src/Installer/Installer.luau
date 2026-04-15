local HttpService = game:GetService("HttpService")
local ServerStorage = game:GetService("ServerStorage")

local Discover = script:FindFirstAncestor("Discover")
local Packages = Discover.Packages

local zzlib = require(Packages.zzlib)

local InstalledPackages = require(Discover.Src.Installer.InstalledPackages)
local PackageTypes = require(Discover.Src.Common.PackageTypes)
local WallyAPI = require(Discover.Src.Wally.Api)

local CONTENTS_API = "https://api.wally.run/v1/package-contents/"
local DEFAULT_EXCLUDE = { ".*", "wally.lock", "Packages", "ServerPackages", "DevPackages", "node_modules", "*.toml" }
local LOCKFILE_NAME = "WallyLock"

local Installer = {}

local verbose = false

local function log(...)
	if verbose then
		print("[Discover]", ...)
	end
end

export type ProgressCallback = (message: string) -> ()

type ResolvedPackage = {
	scope: string,
	name: string,
	version: string,
	realm: "shared" | "server",
	packageId: string,
	dependencies: { { alias: string, packageId: string, realm: "shared" | "server" } },
}

type LockEntry = {
	name: string,
	version: string,
	realm: "shared" | "server",
	dependencies: { { alias: string, packageId: string } },
}

local function parseSemver(version: string): { major: number, minor: number, patch: number }?
	local major, minor, patch = version:match("^(%d+)%.(%d+)%.(%d+)")
	if not major then
		return nil
	end
	return { major = tonumber(major) :: number, minor = tonumber(minor) :: number, patch = tonumber(patch) :: number }
end

local function compareSemver(a: any, b: any): number
	if a.major ~= b.major then
		return if a.major < b.major then -1 else 1
	end
	if a.minor ~= b.minor then
		return if a.minor < b.minor then -1 else 1
	end
	if a.patch ~= b.patch then
		return if a.patch < b.patch then -1 else 1
	end
	return 0
end

local function semverCompatible(a: any, b: any): boolean
	if a.major == b.major and a.minor == b.minor and a.patch == b.patch then
		return true
	end
	if a.major == 0 and b.major == 0 then
		return a.minor == b.minor
	end
	return a.major == b.major
end

local function caretUpperBound(sv: any): any
	if sv.major ~= 0 then
		return { major = sv.major + 1, minor = 0, patch = 0 }
	end
	if sv.minor ~= 0 then
		return { major = 0, minor = sv.minor + 1, patch = 0 }
	end
	return { major = 0, minor = 0, patch = sv.patch + 1 }
end

local function buildSatisfies(constraints: string): (string) -> boolean
	local checks = {}
	for constraint in constraints:gmatch("[^,]+") do
		constraint = constraint:match("^%s*(.-)%s*$")
		local op, ver = constraint:match("^([><=]+)(.+)$")
		if not op then
			local sv = parseSemver(constraint)
			if sv then
				table.insert(checks, { op = ">=", version = sv })
				table.insert(checks, { op = "<", version = caretUpperBound(sv) })
			end
		else
			local sv = parseSemver(ver)
			if sv then
				table.insert(checks, { op = op, version = sv })
			end
		end
	end

	return function(version: string): boolean
		local sv = parseSemver(version)
		if not sv then
			return false
		end
		for _, check in checks do
			local cmp = compareSemver(sv, check.version)
			if check.op == ">=" and cmp < 0 then
				return false
			end
			if check.op == ">" and cmp <= 0 then
				return false
			end
			if check.op == "<=" and cmp > 0 then
				return false
			end
			if check.op == "<" and cmp >= 0 then
				return false
			end
			if check.op == "=" and cmp ~= 0 then
				return false
			end
		end
		return true
	end
end

local function formatPackageId(scope: string, name: string, version: string): string
	return `{scope}_{name}@{version}`
end

local function promoteRealm(existing: string, incoming: string): string
	if existing == "shared" or incoming == "shared" then
		return "shared"
	end
	return "server"
end

local function isDependencyValid(requestRealm: string, dependencyRealm: string): boolean
	if requestRealm == "server" then
		return true
	end
	return dependencyRealm == "shared"
end

local function loadLockfile(): { [string]: LockEntry }
	local lockModule = ServerStorage:FindFirstChild(LOCKFILE_NAME) :: ModuleScript?
	if not lockModule or not lockModule:IsA("ModuleScript") then
		return {}
	end
	local ok, data = pcall(require, lockModule)
	if not ok or type(data) ~= "table" then
		return {}
	end
	local entries: { [string]: LockEntry } = {}
	for _, entry in data :: any do
		local scope, name = entry.name:match("^(.+)/(.+)$")
		if not scope or not name then
			continue
		end
		local packageId = formatPackageId(scope, name, entry.version)
		entries[packageId] = {
			name = entry.name,
			version = entry.version,
			realm = entry.realm or "shared",
			dependencies = entry.dependencies or {},
		}
	end
	return entries
end

local function saveLockfile(resolved: { [string]: ResolvedPackage })
	local lines = { "return {" }
	local sortedIds = {}
	for packageId in resolved do
		table.insert(sortedIds, packageId)
	end
	table.sort(sortedIds)

	for _, packageId in sortedIds do
		local resolvedPackage = resolved[packageId]
		table.insert(lines, "\t{")
		table.insert(lines, `\t\tname = "{resolvedPackage.scope}/{resolvedPackage.name}",`)
		table.insert(lines, `\t\tversion = "{resolvedPackage.version}",`)
		table.insert(lines, `\t\trealm = "{resolvedPackage.realm}",`)
		if #resolvedPackage.dependencies > 0 then
			table.insert(lines, "\t\tdependencies = {")
			for _, dep in resolvedPackage.dependencies do
				local depLine = '\t\t\t{ alias = "' .. dep.alias .. '", packageId = "' .. dep.packageId .. '" },'
				table.insert(lines, depLine)
			end
			table.insert(lines, "\t\t},")
		else
			table.insert(lines, "\t\tdependencies = {},")
		end
		table.insert(lines, "\t},")
	end
	table.insert(lines, "}")

	local existing = ServerStorage:FindFirstChild(LOCKFILE_NAME)
	if existing then
		existing:Destroy()
	end
	local lockModule = Instance.new("ModuleScript")
	lockModule.Name = LOCKFILE_NAME
	lockModule.Source = table.concat(lines, "\n")
	lockModule.Parent = ServerStorage
end

type ActivatedEntry = {
	scope: string,
	name: string,
	version: string,
	semver: { major: number, minor: number, patch: number },
	realm: string,
	packageId: string,
}

type RootRequest = {
	scope: string,
	name: string,
	version: string,
	requestRealm: string,
	alias: string,
}

local function resolveRoots(
	roots: { RootRequest },
	lockfile: { [string]: LockEntry },
	onProgress: ProgressCallback?
): ({ [string]: ResolvedPackage }, { [string]: string }, { string })
	local resolved: { [string]: ResolvedPackage } = {}
	local rootAliases: { [string]: string } = {}
	local failures: { string } = {}

	local activated: { [string]: ActivatedEntry } = {}
	local activatedByName: { [string]: { ActivatedEntry } } = {}

	type DependencyRequest = {
		scope: string,
		name: string,
		constraints: string,
		requestRealm: string,
		originRealm: string,
		requestedBy: string,
		alias: string,
	}

	local queue: { DependencyRequest } = {}

	local function activate(
		dependencyScope: string,
		dependencyName: string,
		dependencyVersion: string,
		dependencyRealm: string,
		packageId: string
	)
		local sv = parseSemver(dependencyVersion)
		if not sv then
			return
		end
		local entry: ActivatedEntry = {
			scope = dependencyScope,
			name = dependencyName,
			version = dependencyVersion,
			semver = sv,
			realm = dependencyRealm,
			packageId = packageId,
		}
		activated[packageId] = entry
		local fullName = `{dependencyScope}/{dependencyName}`
		if not activatedByName[fullName] then
			activatedByName[fullName] = {}
		end
		table.insert(activatedByName[fullName], entry)
	end

	-- Activate every root and queue its direct dependencies.
	for _, root in roots do
		local rootRealm = root.requestRealm
		local rootPackageId = formatPackageId(root.scope, root.name, root.version)

		if onProgress then
			onProgress(`Resolving {root.scope}/{root.name}@{root.version}...`)
		end

		local rootMeta = WallyAPI.metadata(root.scope, root.name)
		if not rootMeta or not rootMeta.versions then
			table.insert(failures, `{root.scope}/{root.name}: metadata unavailable`)
			continue
		end

		local rootVersionData = nil
		for _, vd in rootMeta.versions do
			if vd.package.version == root.version then
				rootVersionData = vd
				break
			end
		end
		if not rootVersionData then
			table.insert(failures, `{root.scope}/{root.name}@{root.version}: version not found`)
			continue
		end

		if rootVersionData.package.realm and rootVersionData.package.realm ~= "dev" then
			rootRealm = promoteRealm(rootRealm, rootVersionData.package.realm)
		end

		activate(root.scope, root.name, root.version, rootRealm, rootPackageId)
		rootAliases[rootPackageId] = root.alias

		local rootDeps: { { alias: string, packageId: string, realm: "shared" | "server" } } = {}
		resolved[rootPackageId] = {
			scope = root.scope,
			name = root.name,
			version = root.version,
			realm = rootRealm :: "shared" | "server",
			packageId = rootPackageId,
			dependencies = rootDeps,
		}

		local depSources = {}
		if rootVersionData.dependencies then
			table.insert(depSources, { deps = rootVersionData.dependencies, requestRealm = "shared" })
		end
		if rootVersionData["server-dependencies"] then
			table.insert(depSources, { deps = rootVersionData["server-dependencies"], requestRealm = "server" })
		end

		for _, source in depSources do
			for depAlias, depValue in source.deps do
				local _, _, constraints = depValue:match("^([^@]+)@(.+)$")
				if not constraints then
					constraints = ""
				end
				table.insert(queue, {
					scope = depValue:match("^(.+)/") or "",
					name = depValue:match("/([^@]+)") or "",
					constraints = constraints,
					requestRealm = source.requestRealm,
					originRealm = source.requestRealm,
					requestedBy = rootPackageId,
					alias = depAlias,
				})
			end
		end
	end

	while #queue > 0 do
		local req = table.remove(queue, 1) :: DependencyRequest
		local fullName = `{req.scope}/{req.name}`
		local satisfies = buildSatisfies(req.constraints)

		local existingMatches = activatedByName[fullName]
		local reused = false
		if existingMatches then
			for _, entry in existingMatches do
				if satisfies(entry.version) then
					local promoted = promoteRealm(entry.realm, req.originRealm)
					if promoted ~= entry.realm then
						entry.realm = promoted
						if resolved[entry.packageId] then
							(resolved[entry.packageId] :: any).realm = promoted
						end
					end

					local parentResolved = resolved[req.requestedBy]
					if parentResolved then
						table.insert(parentResolved.dependencies, {
							alias = req.alias,
							packageId = entry.packageId,
							realm = promoted :: "shared" | "server",
						})
					end
					reused = true
					break
				end
			end
		end

		if reused then
			continue
		end

		if onProgress then
			onProgress(`Resolving {fullName}...`)
		end

		local meta = WallyAPI.metadata(req.scope, req.name)
		if not meta or not meta.versions then
			table.insert(failures, `{fullName}: metadata unavailable`)
			continue
		end

		local candidates = {}
		for _, vd in meta.versions do
			if satisfies(vd.package.version) then
				table.insert(candidates, vd)
			end
		end

		table.sort(candidates, function(a, b)
			local aId = formatPackageId(req.scope, req.name, a.package.version)
			local bId = formatPackageId(req.scope, req.name, b.package.version)
			local aLocked = lockfile[aId] ~= nil
			local bLocked = lockfile[bId] ~= nil
			if aLocked ~= bLocked then
				return aLocked
			end
			local aSv = parseSemver(a.package.version)
			local bSv = parseSemver(b.package.version)
			if aSv and bSv then
				return compareSemver(aSv, bSv) > 0
			end
			return false
		end)

		local chosen = nil
		for _, candidate in candidates do
			local dependencyRealm = candidate.package.realm or "shared"
			if not isDependencyValid(req.requestRealm, dependencyRealm) then
				continue
			end

			local candidateSv = parseSemver(candidate.package.version)
			if not candidateSv then
				continue
			end

			local hasConflict = false
			if existingMatches then
				for _, entry in existingMatches do
					if semverCompatible(candidateSv, entry.semver) then
						hasConflict = true
						break
					end
				end
			end
			if hasConflict then
				continue
			end

			chosen = candidate
			break
		end

		if not chosen then
			table.insert(failures, `{fullName}: no compatible version for "{req.constraints}"`)
			continue
		end

		local chosenVersion = chosen.package.version
		local chosenRealm = promoteRealm(chosen.package.realm or "shared", req.originRealm)
		local chosenPackageId = formatPackageId(req.scope, req.name, chosenVersion)

		activate(req.scope, req.name, chosenVersion, chosenRealm, chosenPackageId)

		local deps: { { alias: string, packageId: string, realm: "shared" | "server" } } = {}
		resolved[chosenPackageId] = {
			scope = req.scope,
			name = req.name,
			version = chosenVersion,
			realm = chosenRealm :: "shared" | "server",
			packageId = chosenPackageId,
			dependencies = deps,
		}

		local parentResolved = resolved[req.requestedBy]
		if parentResolved then
			table.insert(parentResolved.dependencies, {
				alias = req.alias,
				packageId = chosenPackageId,
				realm = chosenRealm :: "shared" | "server",
			})
		end

		local chosenDepSources = {}
		if chosen.dependencies then
			table.insert(chosenDepSources, { deps = chosen.dependencies, requestRealm = "shared" })
		end
		if chosen["server-dependencies"] then
			table.insert(chosenDepSources, { deps = chosen["server-dependencies"], requestRealm = "server" })
		end

		for _, source in chosenDepSources do
			for depAlias, depValue in source.deps do
				local depPath, depConstraints = depValue:match("^([^@]+)@(.+)$")
				if not depPath or not depConstraints then
					table.insert(failures, `{depAlias}: could not parse "{depValue}"`)
					continue
				end
				local dependencyScope, dependencyName = depPath:match("^(.+)/(.+)$")
				if not dependencyScope or not dependencyName then
					table.insert(failures, `{depAlias}: could not parse "{depValue}"`)
					continue
				end
				table.insert(queue, {
					scope = dependencyScope,
					name = dependencyName,
					constraints = depConstraints,
					requestRealm = source.requestRealm,
					originRealm = promoteRealm(source.requestRealm, chosenRealm),
					requestedBy = chosenPackageId,
					alias = depAlias,
				})
			end
		end
	end

	return resolved, rootAliases, failures
end

local function globToPattern(glob: string): string
	local pattern = glob:gsub("([%(%)%.%%%+%-%?%[%]%^%$])", function(c)
		return "%" .. c
	end)
	pattern = pattern:gsub("%*%*", "\0")
	pattern = pattern:gsub("%*", "[^/]*")
	pattern = pattern:gsub("\0", ".*")
	return pattern
end

local function matchesAnyGlob(path: string, globs: { string }): boolean
	for _, glob in globs do
		local anchored = string.sub(glob, 1, 1) == "/"
		local cleanGlob = if anchored then string.sub(glob, 2) else glob
		local pattern = globToPattern(cleanGlob)
		if anchored then
			if string.match(path, "^" .. pattern .. "$") or string.match(path, "^" .. pattern .. "/") then
				return true
			end
		else
			if
				string.match(path, "^" .. pattern .. "$")
				or string.match(path, "^" .. pattern .. "/")
				or string.match(path, "/" .. pattern .. "/")
				or string.match(path, "/" .. pattern .. "$")
			then
				return true
			end
		end
	end
	return false
end

local function parseTomlStringArray(toml: string, key: string): { string }?
	local contents = string.match(toml, key .. "%s*=%s*%[([^%]]*)%]")
	if not contents then
		return nil
	end
	local items = {}
	for value in string.gmatch(contents, '"([^"]*)"') do
		table.insert(items, value)
	end
	return items
end

local function buildFileFilter(wallyToml: string?): (string) -> boolean
	local include: { string }? = nil
	local exclude = table.clone(DEFAULT_EXCLUDE)

	if wallyToml then
		include = parseTomlStringArray(wallyToml, "include")
		local extraExclude = parseTomlStringArray(wallyToml, "exclude")
		if extraExclude then
			for _, pattern in extraExclude do
				table.insert(exclude, pattern)
			end
		end
	end

	return function(path: string): boolean
		if include and #include > 0 then
			return matchesAnyGlob(path, include)
		end
		if matchesAnyGlob(path, exclude) then
			return false
		end
		return true
	end
end

local function classifyFile(path: string): string
	if string.match(path, "%.server%.luau?$") then
		return "Script"
	elseif string.match(path, "%.client%.luau?$") then
		return "LocalScript"
	elseif string.match(path, "%.luau?$") then
		return "ModuleScript"
	else
		return "skip"
	end
end

local function getInstanceName(filename: string): string
	local instanceName = filename
	instanceName = instanceName:gsub("%.server%.luau?$", "")
	instanceName = instanceName:gsub("%.client%.luau?$", "")
	instanceName = instanceName:gsub("%.luau?$", "")
	return instanceName
end

local function buildTree(entries: { { path: string, content: string } }, packageName: string): Folder
	local root = Instance.new("Folder")
	root.Name = packageName

	table.sort(entries, function(a, b)
		local aIsInit = a.path:match("init%.luau?$") ~= nil
		local bIsInit = b.path:match("init%.luau?$") ~= nil
		if aIsInit ~= bIsInit then
			return not aIsInit
		end
		return a.path < b.path
	end)

	for _, entry in entries do
		local parts = string.split(entry.path, "/")

		local className = classifyFile(entry.path)
		if className == "skip" then
			continue
		end

		local startIdx = if #parts > 1 then 2 else 1

		local parent: Instance = root
		for i = startIdx, #parts - 1 do
			local folderName = parts[i]
			if folderName == "" then
				continue
			end
			local existing = parent:FindFirstChild(folderName)
			if not existing then
				existing = Instance.new("Folder")
				existing.Name = folderName
				existing.Parent = parent
			end
			parent = existing
		end

		local fileName = parts[#parts]
		if fileName == "" then
			continue
		end

		local instanceName = getInstanceName(fileName)

		if instanceName == "init" then
			if parent:IsA("Folder") then
				local moduleScript = Instance.new(className)
				moduleScript.Name = parent.Name
				moduleScript.Source = entry.content

				if parent == root then
					for _, child in parent:GetChildren() do
						child.Parent = moduleScript
					end
					parent:Destroy()
					root = moduleScript
				else
					moduleScript.Parent = parent.Parent
					for _, child in parent:GetChildren() do
						child.Parent = moduleScript
					end
					parent:Destroy()
				end
			end
		else
			local inst = Instance.new(className)
			inst.Name = instanceName
			inst.Source = entry.content
			inst.Parent = parent
		end
	end

	return root
end

local function findSourcePath(zipData: string, prefix: string): string?
	local projectFileName = prefix .. "default.project.json"
	local projectJson: string? = nil
	pcall(function()
		projectJson = zzlib.unzip(zipData, projectFileName)
	end)
	if not projectJson then
		return nil
	end

	local decoded = HttpService:JSONDecode(projectJson)
	if not decoded or not decoded.tree then
		return nil
	end

	local path = decoded.tree["$path"]
	if type(path) == "string" and path ~= "" and path ~= "." then
		return (string.gsub(path, "^%./", ""))
	end
	return nil
end

local function downloadAndExtract(scope: string, name: string, version: string): (Folder?, string?)
	local url = `{CONTENTS_API}{scope}/{name}/{version}`

	local ok, result = pcall(function()
		return HttpService:RequestAsync({
			Url = url,
			Method = "GET",
			Headers = {
				["wally-version"] = "0.3.2",
			},
		})
	end)
	if ok and result.Success then
		result = result.Body
	elseif ok then
		return nil, `HTTP {result.StatusCode}: {result.StatusMessage}`
	end
	if not ok then
		return nil, `Failed to download: {result}`
	end

	local prefix = ""
	for _, filename in zzlib.files(result) do
		if string.match(filename, "wally%.toml$") or string.match(filename, "default%.project%.json$") then
			local dir = filename:match("^(.+/)[^/]+$")
			prefix = dir or ""
			break
		end
	end

	log(`Zip prefix: "{prefix}"`)

	local wallyToml: string? = nil
	pcall(function()
		wallyToml = zzlib.unzip(result, prefix .. "wally.toml")
	end)

	local shouldInclude = buildFileFilter(wallyToml)
	local sourcePath = findSourcePath(result, prefix)
	log(`Source path: {sourcePath or "(none)"}`)

	local entries = {}
	local filesOk, filesErr = pcall(function()
		for _, filename, _, _ in zzlib.files(result) do
			if filename:sub(-1) == "/" then
				continue
			end
			local relativePath = string.sub(filename, #prefix + 1)
			if not shouldInclude(relativePath) then
				log(`Filtered out: {relativePath}`)
				continue
			end

			if sourcePath then
				local isUnderSource = string.sub(relativePath, 1, #sourcePath + 1) == sourcePath .. "/"
				local isSourceFile = relativePath == sourcePath
				local isSourceLuau = relativePath == sourcePath .. ".luau" or relativePath == sourcePath .. ".lua"
				if not isUnderSource and not isSourceFile and not isSourceLuau then
					log(`Outside source path: {relativePath}`)
					continue
				end
			end

			local content = zzlib.unzip(result, filename)
			local path = relativePath
			if sourcePath and string.sub(path, 1, #sourcePath + 1) == sourcePath .. "/" then
				path = string.sub(path, #sourcePath + 2)
			elseif sourcePath and (path == sourcePath .. ".luau" or path == sourcePath .. ".lua") then
				path = "init.luau"
			end
			if path ~= "" then
				log(`Extracted: {path}`)
				table.insert(entries, { path = name .. "/" .. path, content = content })
			end
		end
	end)
	if not filesOk then
		return nil, `Failed to extract ZIP: {filesErr}`
	end

	log(`Total entries: {#entries}`)
	return buildTree(entries, name)
end

local function getModuleName(tree: Instance, fallbackName: string): string
	if tree:IsA("ModuleScript") then
		return tree.Name
	end
	for _, child in tree:GetChildren() do
		if child:IsA("ModuleScript") then
			return child.Name
		end
	end
	return fallbackName
end

local function placeTreeInFolder(tree: Instance, folder: Folder)
	if tree:IsA("ModuleScript") then
		tree.Parent = folder
	else
		for _, child in tree:GetChildren() do
			child.Parent = folder
		end
		tree:Destroy()
	end
end

function Installer.getPackagesFolder(realm: string): Folder
	if realm == "server" then
		local folder = ServerStorage:FindFirstChild("ServerPackages")
		if not folder then
			folder = Instance.new("Folder")
			folder.Name = "ServerPackages"
			folder.Parent = ServerStorage
		end
		return folder
	else
		local replicatedStorage = game:GetService("ReplicatedStorage")
		local folder = replicatedStorage:FindFirstChild("Packages")
		if not folder then
			folder = Instance.new("Folder")
			folder.Name = "Packages"
			folder.Parent = replicatedStorage
		end
		return folder
	end
end

local function getOrCreateIndex(packagesFolder: Folder): Folder
	local index = packagesFolder:FindFirstChild("_Index")
	if not index then
		index = Instance.new("Folder")
		index.Name = "_Index"
		index.Parent = packagesFolder
	end
	return index :: Folder
end

local function linkSameIndex(linkName: string, packageId: string, moduleName: string): ModuleScript
	local link = Instance.new("ModuleScript")
	link.Name = linkName
	link.Source = `return require(script.Parent.Parent["{packageId}"]["{moduleName}"])`
	return link
end

local function linkRootSameIndex(linkName: string, packageId: string, moduleName: string): ModuleScript
	local link = Instance.new("ModuleScript")
	link.Name = linkName
	link.Source = `return require(script.Parent._Index["{packageId}"]["{moduleName}"])`
	return link
end

local function linkSharedIndex(linkName: string, packageId: string, moduleName: string): ModuleScript
	local link = Instance.new("ModuleScript")
	link.Name = linkName
	link.Source = `return require(game.ReplicatedStorage.Packages._Index["{packageId}"]["{moduleName}"])`
	return link
end

local function linkServerIndex(linkName: string, packageId: string, moduleName: string): ModuleScript
	local link = Instance.new("ModuleScript")
	link.Name = linkName
	link.Source = `return require(game.ServerStorage.ServerPackages._Index["{packageId}"]["{moduleName}"])`
	return link
end

local function buildPackageLink(
	linkName: string,
	packageId: string,
	moduleName: string,
	sourceRealm: string,
	dependencyRealm: string,
	isRoot: boolean
): ModuleScript
	if sourceRealm == dependencyRealm then
		if isRoot then
			return linkRootSameIndex(linkName, packageId, moduleName)
		end
		return linkSameIndex(linkName, packageId, moduleName)
	elseif dependencyRealm == "shared" then
		return linkSharedIndex(linkName, packageId, moduleName)
	else
		return linkServerIndex(linkName, packageId, moduleName)
	end
end

local function snapshotRoots(): { RootRequest }
	local roots: { RootRequest } = {}
	for _, installedPackage in InstalledPackages.list() do
		table.insert(roots, {
			scope = installedPackage.scope,
			name = installedPackage.name,
			version = installedPackage.version,
			requestRealm = installedPackage.realm,
			alias = installedPackage.aliasLink.Name,
		})
	end
	return roots
end

local function findRootIndex(roots: { RootRequest }, scope: string, name: string): number?
	for index, root in roots do
		if root.scope == scope and root.name == name then
			return index
		end
	end
	return nil
end

local function applyResolved(
	resolved: { [string]: ResolvedPackage },
	rootAliases: { [string]: string },
	onProgress: ProgressCallback?
): { string }
	local failures: { string } = {}
	local moduleNames: { [string]: string } = {}

	-- Wipe all top-level alias links (we'll rebuild them from the resolved
	-- root set below). Anything that's no longer a root will not come back.
	for _, realmName in { "shared", "server" } do
		local packagesFolder = Installer.getPackagesFolder(realmName)
		for _, child in packagesFolder:GetChildren() do
			if child:IsA("ModuleScript") then
				child:Destroy()
			end
		end
	end

	-- Index existing on-disk packages so we can reuse them and avoid
	-- redownloading anything that's already present.
	local existingByPackageId: { [string]: { folder: Folder, realm: "shared" | "server" } } = {}
	for _, realmName in { "shared", "server" } do
		local packagesFolder = Installer.getPackagesFolder(realmName)
		local indexFolder = packagesFolder:FindFirstChild("_Index")
		if indexFolder then
			for _, child in indexFolder:GetChildren() do
				if child:IsA("Folder") then
					existingByPackageId[child.Name] = {
						folder = child,
						realm = realmName :: "shared" | "server",
					}
				end
			end
		end
	end

	-- Destroy any _Index entries that aren't in the resolved set, and any
	-- that need to move to a different realm.
	for packageId, existing in existingByPackageId do
		local resolvedPackage = resolved[packageId]
		if not resolvedPackage or resolvedPackage.realm ~= existing.realm then
			existing.folder:Destroy()
			existingByPackageId[packageId] = nil
		end
	end

	-- Place every resolved package, downloading what isn't already on disk.
	for packageId, resolvedPackage in resolved do
		local packagesFolder = Installer.getPackagesFolder(resolvedPackage.realm)
		local indexFolder = getOrCreateIndex(packagesFolder)

		local existing = existingByPackageId[packageId]
		if existing then
			local moduleName = existing.folder:GetAttribute("ModuleName")
			moduleNames[packageId] = if typeof(moduleName) == "string" then moduleName else resolvedPackage.name

			-- Keep the package code, but wipe and rebuild the dep link
			-- ModuleScripts so they retarget to the resolved versions.
			for _, child in existing.folder:GetChildren() do
				if child:IsA("ModuleScript") then
					child:Destroy()
				end
			end
			continue
		end

		if onProgress then
			onProgress(`Downloading {resolvedPackage.scope}/{resolvedPackage.name}@{resolvedPackage.version}...`)
		end
		local tree, errorMessage =
			downloadAndExtract(resolvedPackage.scope, resolvedPackage.name, resolvedPackage.version)
		if not tree then
			table.insert(
				failures,
				`{resolvedPackage.scope}/{resolvedPackage.name}@{resolvedPackage.version}: {errorMessage}`
			)
			warn(
				`[Discover] Failed to download {resolvedPackage.scope}/{resolvedPackage.name}@{resolvedPackage.version}: {errorMessage}`
			)
			continue
		end

		local moduleName = getModuleName(tree, resolvedPackage.name)
		moduleNames[packageId] = moduleName

		local packageFolder = Instance.new("Folder")
		packageFolder.Name = packageId
		packageFolder:SetAttribute("ModuleName", moduleName)
		placeTreeInFolder(tree, packageFolder)
		packageFolder.Parent = indexFolder
	end

	-- Rebuild internal dep links for every resolved package.
	for packageId, resolvedPackage in resolved do
		local packagesFolder = Installer.getPackagesFolder(resolvedPackage.realm)
		local indexFolder = getOrCreateIndex(packagesFolder)
		local packageFolder = indexFolder:FindFirstChild(packageId) :: Folder?
		if not packageFolder then
			continue
		end

		for _, dep in resolvedPackage.dependencies do
			local depResolved = resolved[dep.packageId]
			if not depResolved then
				continue
			end
			local dependencyModuleName = moduleNames[dep.packageId] or depResolved.name
			local link = buildPackageLink(
				dep.alias,
				dep.packageId,
				dependencyModuleName,
				resolvedPackage.realm,
				depResolved.realm,
				false
			)
			link.Parent = packageFolder
			PackageTypes.processLink(link)
		end
	end

	-- Recreate top-level alias links from the resolved root set.
	for packageId, alias in rootAliases do
		local resolvedPackage = resolved[packageId]
		if not resolvedPackage then
			continue
		end
		local packagesFolder = Installer.getPackagesFolder(resolvedPackage.realm)
		local moduleName = moduleNames[packageId] or resolvedPackage.name
		local rootLink =
			buildPackageLink(alias, packageId, moduleName, resolvedPackage.realm, resolvedPackage.realm, true)
		rootLink.Parent = packagesFolder
		PackageTypes.processLink(rootLink)
	end

	return failures
end

function Installer.install(
	scope: string,
	name: string,
	version: string,
	alias: string,
	realm: string?,
	onProgress: ProgressCallback?
): (boolean, string?, { string }?)
	local function progress(message: string)
		if onProgress then
			onProgress(message)
		end
	end

	if realm == "dev" then
		return false, "Dev realm packages are not supported. Discover can only install shared and server packages."
	end

	local roots = snapshotRoots()
	local existingIndex = findRootIndex(roots, scope, name)
	local newRoot: RootRequest = {
		scope = scope,
		name = name,
		version = version,
		requestRealm = realm or "shared",
		alias = alias,
	}
	if existingIndex then
		roots[existingIndex] = newRoot
	else
		table.insert(roots, newRoot)
	end

	progress("Resolving dependencies...")
	local resolved, rootAliases, resolutionFailures = resolveRoots(roots, loadLockfile(), onProgress)

	local missingRoots: { string } = {}
	for _, root in roots do
		local rootPackageId = formatPackageId(root.scope, root.name, root.version)
		if not resolved[rootPackageId] then
			table.insert(missingRoots, `{root.scope}/{root.name}@{root.version}`)
		end
	end
	if #missingRoots > 0 then
		-- Bail out before destroying anything. If a previously-installed
		-- root can't be re-resolved (e.g. transient metadata fetch
		-- failure), applyResolved would treat it as an orphan and wipe it.
		local message = `Cannot resolve already-installed packages: {table.concat(missingRoots, ", ")}`
		if #resolutionFailures > 0 then
			message = `{message} ({table.concat(resolutionFailures, "; ")})`
		end
		return false, message
	end

	local applyFailures = applyResolved(resolved, rootAliases, onProgress)
	saveLockfile(resolved)

	local failures = {}
	for _, failure in resolutionFailures do
		table.insert(failures, failure)
	end
	for _, failure in applyFailures do
		table.insert(failures, failure)
	end

	if #failures > 0 then
		return true, nil, failures
	end
	return true, nil
end

function Installer.uninstall(scope: string, name: string): (boolean, string?)
	local roots = snapshotRoots()
	local existingIndex = findRootIndex(roots, scope, name)
	if not existingIndex then
		return false, "Package not found"
	end

	table.remove(roots, existingIndex)

	local resolved, rootAliases, resolutionFailures = resolveRoots(roots, loadLockfile(), nil)

	local missingRoots: { string } = {}
	for _, root in roots do
		local rootPackageId = formatPackageId(root.scope, root.name, root.version)
		if not resolved[rootPackageId] then
			table.insert(missingRoots, `{root.scope}/{root.name}@{root.version}`)
		end
	end
	if #missingRoots > 0 then
		local message = `Cannot resolve remaining packages: {table.concat(missingRoots, ", ")}`
		if #resolutionFailures > 0 then
			message = `{message} ({table.concat(resolutionFailures, "; ")})`
		end
		return false, message
	end

	applyResolved(resolved, rootAliases, nil)
	saveLockfile(resolved)

	return true, nil
end

function Installer.setVerbose(enabled: boolean)
	verbose = enabled
end

return Installer
