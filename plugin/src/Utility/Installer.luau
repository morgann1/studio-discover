local HttpService = game:GetService("HttpService")

local Discover = script:FindFirstAncestor("Discover")
local zzlib = require(Discover.Src.Utility.zzlib)

local WALLY_CONTENTS_API = "https://api.wally.run/v1/package-contents/"

local InstalledPackages = require(Discover.Src.Utility.InstalledPackages)
local PackageTypes = require(Discover.Src.Utility.PackageTypes)
local WallyAPI = require(Discover.Src.Utility.WallyAPI)

local Installer = {}

-- Returns the set of packageIds currently reachable from any top-level
-- alias link in the given _Index folder (i.e. "still needed" packages).
local function collectReachable(packagesFolder: Folder, indexFolder: Folder): { [string]: true }
	local reachable: { [string]: true } = {}

	local function extractPackageId(source: string): string?
		return source:match('_Index%["([^"]+)"%]')
	end

	local function visit(packageId: string)
		if reachable[packageId] then
			return
		end
		reachable[packageId] = true
		local pkgFolder = indexFolder:FindFirstChild(packageId)
		if not pkgFolder then
			return
		end
		for _, child in pkgFolder:GetChildren() do
			if child:IsA("ModuleScript") then
				local depId = extractPackageId(child.Source)
				if depId then
					visit(depId)
				end
			end
		end
	end

	for _, child in packagesFolder:GetChildren() do
		if child:IsA("ModuleScript") then
			local id = extractPackageId(child.Source)
			if id then
				visit(id)
			end
		end
	end
	return reachable
end

local function parseSemver(version: string): { major: number, minor: number, patch: number }?
	local major, minor, patch = version:match("^(%d+)%.(%d+)%.(%d+)")
	if not major then
		return nil
	end
	return { major = tonumber(major), minor = tonumber(minor), patch = tonumber(patch) }
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

local function parseDependency(depValue: string): (string?, string?, (string) -> boolean)
	local path, constraints = depValue:match("^([^@]+)@(.+)$")
	if not path then
		return nil, nil, function()
			return false
		end
	end

	local depScope, depName = path:match("^(.+)/(.+)$")
	if not depScope then
		return nil, nil, function()
			return false
		end
	end

	local checks = {}
	for constraint in constraints:gmatch("[^,]+") do
		constraint = constraint:match("^%s*(.-)%s*$")
		local op, ver = constraint:match("^([><=]+)(.+)$")
		if not op then
			local sv = parseSemver(constraint)
			if sv then
				table.insert(checks, { op = ">=", version = sv })
				table.insert(checks, { op = "<", version = { major = sv.major + 1, minor = 0, patch = 0 } })
			end
		else
			local sv = parseSemver(ver)
			if sv then
				table.insert(checks, { op = op, version = sv })
			end
		end
	end

	local function satisfies(version: string): boolean
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

	return depScope, depName, satisfies
end

local function resolveDependencyVersion(depScope: string, depName: string, satisfies: (string) -> boolean): string?
	local meta = WallyAPI.metadata(depScope, depName)
	if not meta or not meta.versions then
		return nil
	end

	for _, versionData in meta.versions do
		local v = versionData.package.version
		if satisfies(v) then
			return v
		end
	end
	return nil
end

local function classifyFile(path: string): (string, string?)
	if string.match(path, "%.server%.luau?$") then
		return "Script", "Server"
	elseif string.match(path, "%.client%.luau?$") then
		return "LocalScript", "Client"
	elseif string.match(path, "%.luau?$") then
		return "ModuleScript", nil
	else
		return "skip", nil
	end
end

local function getInstanceName(filename: string): string
	local name = filename
	name = name:gsub("%.server%.luau?$", "")
	name = name:gsub("%.client%.luau?$", "")
	name = name:gsub("%.luau?$", "")
	return name
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

		local className, _ = classifyFile(entry.path)
		if className == "skip" then
			continue
		end

		local startIdx = 1
		if #parts > 1 then
			startIdx = 2
		end

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
			local script = Instance.new(className)
			script.Name = instanceName
			script.Source = entry.content
			script.Parent = parent
		end
	end

	return root
end

function Installer.downloadPackage(scope: string, name: string, version: string): (Folder?, string?)
	local url = `{WALLY_CONTENTS_API}{scope}/{name}/{version}`

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

	local entries = {}
	local filesOk, filesErr = pcall(function()
		for _, filename, _, _ in zzlib.files(result) do
			if filename:sub(-1) ~= "/" then
				local content = zzlib.unzip(result, filename)
				table.insert(entries, { path = filename, content = content })
			end
		end
	end)
	if not filesOk then
		return nil, `Failed to extract ZIP: {filesErr}`
	end

	local tree = buildTree(entries, name)
	return tree, nil, entries
end

function Installer.getPackagesFolder(realm: string): Folder
	if realm == "server" then
		local serverStorage = game:GetService("ServerStorage")
		local folder = serverStorage:FindFirstChild("ServerPackages")
		if not folder then
			folder = Instance.new("Folder")
			folder.Name = "ServerPackages"
			folder.Parent = serverStorage
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

export type ProgressCallback = (message: string) -> ()

function Installer.install(
	scope: string,
	name: string,
	version: string,
	alias: string,
	realm: string?,
	onProgress: ProgressCallback?
): (boolean, string?, { string }?)
	local function progress(msg: string)
		if onProgress then
			onProgress(msg)
		end
	end
	local packagesFolder = Installer.getPackagesFolder(realm or "shared")
	local indexFolder = packagesFolder:FindFirstChild("_Index")
	if not indexFolder then
		indexFolder = Instance.new("Folder")
		indexFolder.Name = "_Index"
		indexFolder.Parent = packagesFolder
	end

	local packageId = `{scope}_{name}@{version}`
	local pkgFolder = indexFolder:FindFirstChild(packageId) :: Folder?
	local moduleName: string? = nil

	if pkgFolder then
		progress("Already downloaded, relinking...")
		-- Reuse existing indexed folder; derive moduleName from its first ModuleScript child
		for _, child in pkgFolder:GetChildren() do
			if child:IsA("ModuleScript") then
				moduleName = child.Name
				break
			end
		end
	else
		progress(`Downloading {scope}/{name}@{version}...`)
		local tree, err = Installer.downloadPackage(scope, name, version)
		if not tree then
			return false, err
		end

		moduleName = name
		if tree:IsA("ModuleScript") then
			moduleName = tree.Name
		else
			for _, child in tree:GetChildren() do
				if child:IsA("ModuleScript") then
					moduleName = child.Name
					break
				end
			end
		end

		pkgFolder = Instance.new("Folder")
		pkgFolder.Name = packageId

		if tree:IsA("ModuleScript") then
			tree.Parent = pkgFolder
		else
			for _, child in tree:GetChildren() do
				child.Parent = pkgFolder
			end
			tree:Destroy()
		end

		pkgFolder.Parent = indexFolder
	end

	-- Replace any existing alias link (e.g. version upgrade)
	local existing = packagesFolder:FindFirstChild(alias)
	if existing then
		existing:Destroy()
	end

	local link = Instance.new("ModuleScript")
	link.Name = alias
	link.Source = `return require(script.Parent._Index["{packageId}"]["{moduleName}"])`
	link.Parent = packagesFolder

	PackageTypes.processLink(link)

	progress("Resolving dependencies...")
	local failures = {}
	Installer._installDeps(packagesFolder, indexFolder, pkgFolder, scope, name, version, realm, failures, progress)

	-- GC: drop any _Index folders no longer reachable from a top-level alias.
	-- This replaces the naive prefix-based delete that could orphan shared
	-- transitive deps used by other installed packages.
	local reachable = collectReachable(packagesFolder, indexFolder)
	for _, child in indexFolder:GetChildren() do
		if not reachable[child.Name] then
			child:Destroy()
		end
	end

	if #failures > 0 then
		return true, nil, failures
	end
	return true, nil
end

function Installer._installDeps(
	packagesFolder: Folder,
	indexFolder: Folder,
	pkgFolder: Folder,
	scope: string,
	name: string,
	version: string,
	realm: string?,
	failures: { string },
	progress: ((string) -> ())?
)
	local function report(msg: string)
		if progress then
			progress(msg)
		end
	end
	local meta = WallyAPI.metadata(scope, name)
	if not meta or not meta.versions then
		return
	end

	local versionData = nil
	for _, vd in meta.versions do
		if vd.package.version == version then
			versionData = vd
			break
		end
	end
	if not versionData then
		return
	end

	local allDeps = {}
	if versionData.dependencies then
		for depAlias, depValue in versionData.dependencies do
			table.insert(allDeps, { alias = depAlias, value = depValue })
		end
	end
	if versionData["server-dependencies"] then
		for depAlias, depValue in versionData["server-dependencies"] do
			table.insert(allDeps, { alias = depAlias, value = depValue })
		end
	end
	if versionData["dev-dependencies"] then
		for depAlias, depValue in versionData["dev-dependencies"] do
			table.insert(allDeps, { alias = depAlias, value = depValue })
		end
	end

	for _, dep in allDeps do
		local depScope, depName, satisfies = parseDependency(dep.value)
		if not depScope or not depName then
			table.insert(failures, `{dep.alias}: could not parse dependency "{dep.value}"`)
			continue
		end

		local depVersion = resolveDependencyVersion(depScope, depName, satisfies)
		if not depVersion then
			table.insert(failures, `{depScope}/{depName}: no version satisfies "{dep.value}"`)
			continue
		end

		local depPackageId = `{depScope}_{depName}@{depVersion}`

		if not indexFolder:FindFirstChild(depPackageId) then
			report(`Installing {depScope}/{depName}@{depVersion}...`)
			local depTree, depErr = Installer.downloadPackage(depScope, depName, depVersion)
			if depTree then
				local depPkgFolder = Instance.new("Folder")
				depPkgFolder.Name = depPackageId

				local depModuleName = depName
				if depTree:IsA("ModuleScript") then
					depModuleName = depTree.Name
					depTree.Parent = depPkgFolder
				else
					for _, child in depTree:GetChildren() do
						if child:IsA("ModuleScript") and depModuleName == depName then
							depModuleName = child.Name
						end
						child.Parent = depPkgFolder
					end
					depTree:Destroy()
				end

				depPkgFolder:SetAttribute("ModuleName", depModuleName)
				depPkgFolder.Parent = indexFolder

				Installer._installDeps(
					packagesFolder,
					indexFolder,
					depPkgFolder,
					depScope,
					depName,
					depVersion,
					realm,
					failures,
					progress
				)
			else
				table.insert(failures, `{depScope}/{depName}@{depVersion}: {depErr}`)
				warn(`[Discover] Failed to install dependency {depScope}/{depName}@{depVersion}: {depErr}`)
			end
		end

		local existingLink = pkgFolder:FindFirstChild(dep.alias)
		if not existingLink then
			local depModuleName = depName
			local depPkg = indexFolder:FindFirstChild(depPackageId)
			if depPkg then
				local stored = depPkg:GetAttribute("ModuleName")
				if stored then
					depModuleName = stored
				end
			end

			local depLink = Instance.new("ModuleScript")
			depLink.Name = dep.alias
			depLink.Source = `return require(script.Parent.Parent["{depPackageId}"]["{depModuleName}"])`
			depLink.Parent = pkgFolder

			PackageTypes.processLink(depLink)
		end
	end
end

function Installer.uninstall(scope: string, name: string): (boolean, string?)
	local installed = InstalledPackages.map()
	local entry = installed[`{scope}/{name}`]
	if not entry then
		return false, "Package not found"
	end

	-- Remove the alias link (so subsequent reachability walk excludes it)
	entry.aliasLink:Destroy()

	local packagesFolder = Installer.getPackagesFolder(entry.realm)
	local indexFolder = packagesFolder:FindFirstChild("_Index") :: Folder?
	if not indexFolder then
		return true, nil
	end

	-- After alias removal, recompute what's still reachable from remaining
	-- top-level packages. Any indexed folder not in this set is garbage.
	local reachable = collectReachable(packagesFolder, indexFolder)
	for _, child in indexFolder:GetChildren() do
		if not reachable[child.Name] then
			child:Destroy()
		end
	end

	return true, nil
end

return Installer
