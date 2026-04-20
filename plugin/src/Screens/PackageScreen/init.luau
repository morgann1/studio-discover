--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local Foundation = require(StudioDiscover.Packages.Foundation)
local React = require(StudioDiscover.Packages.React)

local Content = require(StudioDiscover.Source.Common.Content)
local Installer = require(StudioDiscover.Source.Installer)
local Navigation = require(StudioDiscover.Source.Navigation)
local Screen = require(StudioDiscover.Source.Common.Screen)
local Section = require(StudioDiscover.Source.Common.Section)
local capitalize = require(StudioDiscover.Source.Util.capitalize)
local createNextOrder = require(StudioDiscover.Source.Util.createNextOrder)
local types = require(StudioDiscover.Source.Api.types)
local usePackageMetadata = require(StudioDiscover.Source.Api.usePackageMetadata)

local Dependencies = require(script.Dependencies)
local Hero = require(script.Hero)

local Loading = Foundation.Loading
local Text = Foundation.Text
local View = Foundation.View

local e = React.createElement

local function findVersion(data: types.WallyPackageMetadata, version: string): types.WallyPackageVersion
	for _, entry in data.versions do
		if entry.package.version == version then
			return entry
		end
	end
	return data.versions[1]
end

local function countEntries(map: { [string]: any }): number
	local count = 0
	for _ in map do
		count += 1
	end
	return count
end

local function aboutRow(label: string, value: string, order: number): React.ReactNode
	local nextChildOrder = createNextOrder()
	return e(View, {
		tag = "size-full-0 auto-y row align-y-center gap-medium",
		LayoutOrder = order,
	}, {
		Label = e(Text, {
			tag = "auto-xy text-body-small content-muted",
			Text = `{label}:`,
			LayoutOrder = nextChildOrder(),
		}),
		Value = e(Text, {
			tag = "grow auto-y text-body-small content-default text-align-x-left text-truncate",
			Text = value,
			LayoutOrder = nextChildOrder(),
		}),
	})
end

local function PackageScreen()
	local screen = Navigation.useScreen()
	local scope = (screen.options.scope :: string?) or ""
	local name = (screen.options.name :: string?) or ""
	local requestedVersion = (screen.options.version :: string?) or ""
	local registry: types.Registry = (screen.options.registry :: types.Registry?) or "wally"

	local state = usePackageMetadata(scope, name, registry)
	local installerState = Installer.useInstaller()
	local installedRoots = Installer.useInstalledRoots().roots
	local selectedVersion, setSelectedVersion = React.useState("")

	React.useEffect(function()
		if state.data == nil or #state.data.versions == 0 then
			return
		end

		if requestedVersion ~= "" then
			for _, entry in state.data.versions do
				if entry.package.version == requestedVersion then
					setSelectedVersion(requestedVersion)
					return
				end
			end
		end

		setSelectedVersion(state.data.versions[1].package.version)
	end, { state.data, requestedVersion } :: { any })

	local title = if scope ~= "" and name ~= "" then `{scope}/{name}` else "Package"

	local body: React.ReactNode
	if state.loading then
		body = e(View, {
			tag = "size-full align-x-center align-y-center",
		}, {
			Spinner = e(Loading, {}),
		})
	elseif state.error ~= nil then
		body = e(View, {
			tag = "size-full align-x-center align-y-center padding-large",
		}, {
			Message = e(Text, {
				tag = "auto-xy text-body-medium content-muted",
				Text = `Couldn't load package: {state.error}`,
			}),
		})
	elseif state.data == nil or #state.data.versions == 0 then
		body = e(View, {
			tag = "size-full align-x-center align-y-center padding-large",
		}, {
			Message = e(Text, {
				tag = "auto-xy text-body-medium content-muted",
				Text = "Package not found.",
			}),
		})
	else
		local metadata = state.data
		local selected = findVersion(metadata, selectedVersion)
		local pkg = selected.package

		local hasDescription = pkg.description ~= nil and pkg.description:match("%S") ~= nil
		local description: string = if hasDescription
			then pkg.description :: string
			else `{capitalize(name)} has no provided description.`

		local license = pkg.license or "Unknown"

		local versionItems: { Foundation.DropdownItem } = {}
		for i, entry in metadata.versions do
			local v = entry.package.version
			table.insert(versionItems, {
				id = v,
				text = if i == 1 then `v{v} (latest)` else `v{v}`,
			})
		end

		local depSections: { [string]: any } = {}
		local depOrder = createNextOrder()
		local function addDepSection(label: string, deps: types.WallyDependencyMap, key: string)
			if countEntries(deps) == 0 then
				return
			end
			depSections[key] = e(Dependencies, {
				label = label,
				deps = deps,
				LayoutOrder = depOrder(),
			})
		end
		addDepSection("Shared", selected.dependencies, "Shared")
		addDepSection("Server", selected["server-dependencies"], "Server")
		addDepSection("Dev", selected["dev-dependencies"], "Dev")

		local nextOrder = createNextOrder()

		local aboutOrder = createNextOrder()
		local aboutChildren: { [string]: any } = {
			License = aboutRow("License", license, aboutOrder()),
			Realm = aboutRow("Realm", capitalize(pkg.realm), aboutOrder()),
			Versions = aboutRow("Versions", tostring(#metadata.versions), aboutOrder()),
		}

		local installRealm: "shared" | "server" = if pkg.realm == "server" then "server" else "shared"
		local activeVersion = if selectedVersion ~= "" then selectedVersion else pkg.version
		local onInstall = function()
			task.spawn(function()
				Installer.installAsync(scope, name, activeVersion, name, installRealm)
			end)
		end

		local target = installerState.target
		local isForThisPackage = target ~= nil
			and target.scope == scope
			and target.name == name
			and target.version == activeVersion
		local isPersistedInstalled = false
		for _, root in installedRoots do
			if root.scope == scope and root.name == name and root.version == activeVersion then
				isPersistedInstalled = true
				break
			end
		end
		local heroStatus: "idle" | "running" | "success" | "error"
		local heroMessage: string?
		if isForThisPackage and installerState.status == "running" then
			heroStatus = "running"
			heroMessage = installerState.message
		elseif isForThisPackage and installerState.status == "error" then
			heroStatus = "error"
			heroMessage = installerState.message
		elseif isPersistedInstalled then
			heroStatus = "success"
			heroMessage = nil
		else
			heroStatus = "idle"
			heroMessage = nil
		end

		body = e(Content, {}, {
			Hero = e(Hero, {
				scope = scope,
				name = name,
				authors = pkg.authors,
				description = description,
				selectedVersion = activeVersion,
				versionItems = versionItems,
				onVersionChanged = setSelectedVersion,
				installStatus = heroStatus,
				installMessage = heroMessage,
				isInstallBlocked = pkg.realm == "dev" or registry == "pesde",
				onInstall = onInstall,
				LayoutOrder = nextOrder(),
			}),

			About = e(Section, {
				title = "About",
				LayoutOrder = nextOrder(),
			}, aboutChildren),

			DependenciesSection = if next(depSections) ~= nil
				then e(Section, {
					title = "Dependencies",
					LayoutOrder = nextOrder(),
				}, depSections)
				else nil,
		})
	end

	return e(Screen, {
		title = title,
		onBack = Navigation.popScreen,
	}, {
		Body = body,
	})
end

return PackageScreen
