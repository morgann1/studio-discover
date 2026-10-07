--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const Foundation = require(StudioDiscover.Packages.Foundation)
const React = require(StudioDiscover.Packages.React)

const InstallConfirmDialog = require(StudioDiscover.Source.Installer.InstallConfirmDialog)
const Installer = require(StudioDiscover.Source.Installer)
const LoadError = require(StudioDiscover.Source.Common.LoadError)
const MajorBadge = require(StudioDiscover.Source.Common.MajorBadge)
const Message = require(StudioDiscover.Source.Common.Message)
const Navigation = require(StudioDiscover.Source.Navigation)
const NoticeStore = require(StudioDiscover.Source.NoticeStore)
const Screen = require(StudioDiscover.Source.Common.Screen)
const SearchStore = require(StudioDiscover.Source.SearchStore)
const SettingsStore = require(StudioDiscover.Source.SettingsStore)
const capitalize = require(StudioDiscover.Source.Util.capitalize)
const coreTypes = require(StudioDiscover.Libraries.Core.types)
const createNextOrder = require(StudioDiscover.Source.Util.createNextOrder)
const escapeRichText = require(StudioDiscover.Source.Util.escapeRichText)
const installerTypes = require(StudioDiscover.Source.Installer.types)
const isBreakingUpdate = require(StudioDiscover.Libraries.Semver.isBreakingUpdate)
const isNewerVersion = require(StudioDiscover.Libraries.Semver.isNewerVersion)
const isRegistryEnabled = require(StudioDiscover.Source.Util.isRegistryEnabled)
const packageDisplayName = require(StudioDiscover.Source.Util.packageDisplayName)
const packagesPath = require(StudioDiscover.Source.Util.packagesPath)
const registryLabel = require(StudioDiscover.Source.Util.registryLabel)
const rootDisplayName = require(StudioDiscover.Source.Util.rootDisplayName)
const useBreakpoint = require(StudioDiscover.Source.Common.useBreakpoint)
const useOperation = require(StudioDiscover.Source.Common.useOperation)
const usePackageMetadata = require(StudioDiscover.Source.Api.usePackageMetadata)

const Dependencies = require(script.Dependencies)
const Facts = require(script.Facts)
const Head = require(script.Head)
const Versions = require(script.Versions)

const Alert = Foundation.Alert
const ScrollView = Foundation.ScrollView
const Tabs = Foundation.Tabs
const Text = Foundation.Text
const View = Foundation.View
const AlertSeverity = Foundation.Enums.AlertSeverity
const AlertVariant = Foundation.Enums.AlertVariant
const Breakpoint = Foundation.Enums.Breakpoint
const InputSize = Foundation.Enums.InputSize

const e = React.createElement

type Tab = "description" | "versions" | "dependencies"

const function findVersion(metadata: coreTypes.PackageMetadata, version: string): coreTypes.PackageVersion
	for _, entry in metadata.versions do
		if entry.package.version == version then
			return entry
		end
	end

	return metadata.versions[1]
end

const function findRoot(roots: { coreTypes.InstalledRoot }, target: Navigation.PackageTarget): coreTypes.InstalledRoot?
	for _, root in roots do
		if root.registry == target.registry and root.scope == target.scope and root.name == target.name then
			return root
		end
	end

	return nil
end

-- The dependencies an install brings in, sorted. Dev dependencies never install, so they're left out.
const function installedSpecs(version: coreTypes.PackageVersion): { string }
	const specs: { string } = {}
	for _, spec in version.dependencies do
		table.insert(specs, spec)
	end

	for _, spec in version["server-dependencies"] do
		table.insert(specs, spec)
	end

	table.sort(specs)

	return specs
end

const function openSettings()
	Navigation.resetScreen({ name = "Settings" })
end

const function alert(severity: Foundation.AlertSeverity, text: string, layoutOrder: number): React.Node
	return e(Alert, {
		variant = AlertVariant.Feedback,
		severity = severity,
		text = text,
		LayoutOrder = layoutOrder,
	})
end

--[[
	One package: what it is, where it would go, and the version to install. Installed
		packages offer the update or the removal instead.
]]
const function PackageScreen(props: {
	read target: Navigation.PackageTarget,
})
	const target = props.target
	const registry, scope, name = target.registry, target.scope, target.name

	const settings = SettingsStore.useSettings()
	const installer = Installer.useInstaller()
	const isBusy = Installer.useIsBusy()
	const roots = Installer.useInstalledRoots().roots
	const state = usePackageMetadata(registry, scope, name)
	const removal = useOperation()

	const selectedVersion, setSelectedVersion = React.useState("")
	const tab, setTab = React.useState<<Tab>>("description")
	const isConfirming, setIsConfirming = React.useState(false)
	const pane, setPane = React.useState<<GuiObject?>>(nil)
	const breakpoint = useBreakpoint(pane)

	React.useEffect(function()
		const metadata = state.data
		if metadata == nil or #metadata.versions == 0 then
			return
		end

		-- findVersion falls back to the latest when the requested version is not listed.
		setSelectedVersion(findVersion(metadata, target.version or "").package.version)
	end, { state.data, target.version } :: { unknown })

	const label = registryLabel(registry)
	const displayName = packageDisplayName(registry, name, settings)
	const root = findRoot(roots, target)
	const metadata = state.data

	local body: React.Node
	if not isRegistryEnabled(settings.registries, registry) then
		body = e(Message, {
			text = `{label} is turned off.`,
			action = { text = "Open Settings", onActivated = openSettings },
		})
	elseif state.loading then
		body = e(Message, { text = `Loading {displayName}...` })
	elseif state.error ~= nil then
		body = e(LoadError, { text = `Couldn't load {displayName}: {state.error}` })
	elseif metadata == nil or #metadata.versions == 0 then
		body = e(Message, { text = `{label} has no package {scope}/{name}.` })
	else
		const selected = findVersion(metadata, selectedVersion)
		const pkg = selected.package
		const version = pkg.version
		const realm: coreTypes.Realm = if pkg.realm == "server" then "server" else "shared"
		const isDev = pkg.realm == "dev"

		const request: installerTypes.InstallRequest = {
			registry = registry,
			scope = scope,
			name = name,
			version = version,
			realm = realm,
		}

		-- The installer's state belongs to whichever package it last ran for.
		const installTarget = installer.target
		const isInstallerTarget = installTarget ~= nil
			and installTarget.scope == scope
			and installTarget.name == name
			and installTarget.version == version
		const isInstalling = isInstallerTarget and installer.status == "running"
		const installError = if isInstallerTarget and installer.status == "error" then installer.message else nil

		const isUpdate = root ~= nil and isNewerVersion(version, root.version)
		const isMajor = isUpdate and root ~= nil and isBreakingUpdate(root.version, version)

		const function install()
			task.spawn(Installer.installAsync, request)
		end

		-- The installed version offers its removal, so the page has a way back out.
		local action: Head.Action
		if isInstalling or removal.isRunning then
			action = {
				text = if isInstalling then "Installing..." else "Removing...",
				isEmphasized = isInstalling,
				isDisabled = true,
				onActivated = function() end,
			}
		elseif root ~= nil and root.version == version then
			action = {
				text = "Remove",
				isEmphasized = false,
				isDisabled = isBusy,
				onActivated = function()
					removal.run(function()
						const result = Installer.uninstallAsync(root)
						NoticeStore.showSuccess(
							result,
							`Removed {rootDisplayName(root, settings)}`,
							"Undo with Ctrl+Z."
						)

						return result
					end)
				end,
			}
		else
			const isDowngrade = root ~= nil and not isUpdate

			action = {
				text = if isUpdate then "Update" elseif isDowngrade then "Downgrade" else "Install",
				isEmphasized = not isDowngrade,
				isDisabled = isDev or isBusy,
				onActivated = function()
					if settings.confirmBeforeInstall then
						setIsConfirming(true)
					else
						install()
					end
				end,
			}
		end

		const versionItems: { Foundation.DropdownItem } = {}
		const versionList: { string } = {}
		for index, entry in metadata.versions do
			const itemVersion = entry.package.version
			table.insert(versionList, itemVersion)
			table.insert(versionItems, {
				id = itemVersion,
				text = if index == 1 then `{itemVersion} (latest)` else itemVersion,
			})
		end

		local notice: string
		if isInstalling then
			notice = escapeRichText(installer.message or "Installing...")
		elseif root ~= nil then
			notice =
				`Installed as <b>{escapeRichText(root.alias)}</b> in {packagesPath(registry, root.realm)}, version {root.version}`
		else
			notice =
				`Adds <b>{escapeRichText(displayName)}</b> to {packagesPath(registry, realm)} as {scope}/{name} {version}`
		end

		const specs = installedSpecs(selected)
		const description = pkg.description
		const nextOrder = createNextOrder()

		-- Nevermore has no realms, since its loader replicates each folder by name.
		const realmFact: Facts.Fact? = if registry == "nevermore"
			then nil
			else {
				label = "Realm",
				value = e(Text, {
					tag = "auto-xy text-body-medium content-emphasis",
					Text = capitalize(pkg.realm),
				}),
			}

		const facts: { Facts.Fact } = {
			{
				label = "Version",
				value = e(View, {
					tag = "auto-xy row align-y-center gap-small",
				}, {
					Version = e(Text, {
						tag = "auto-xy text-body-medium content-emphasis",
						Text = version,
						LayoutOrder = 1,
					}),
					Major = isMajor and e(MajorBadge, {
						LayoutOrder = 2,
					}),
				}),
			},
			{
				label = "License",
				value = e(Text, {
					tag = "auto-xy text-body-medium content-emphasis",
					Text = pkg.license or "Unknown",
				}),
			},
			{
				label = "Versions",
				value = e(Text, {
					tag = "auto-xy text-body-medium content-emphasis",
					Text = tostring(#metadata.versions),
				}),
			},
		}
		if realmFact ~= nil then
			table.insert(facts, 3, realmFact)
		end

		local tabBody: React.Node
		if tab == "versions" then
			tabBody = e(Versions, {
				versions = versionList,
				selected = version,
				installed = if root ~= nil then root.version else nil,
				onSelected = setSelectedVersion,
			})
		elseif tab == "dependencies" then
			tabBody = if #specs > 0
				then e(Dependencies, {
					specs = specs,
					registry = registry,
				})
				else e(Text, {
					tag = "size-full-0 auto-y text-body-medium content-muted text-align-x-left",
					Text = `{displayName} {version} has no dependencies.`,
				})
		else
			tabBody = e(Text, {
				tag = "size-full-0 auto-y text-body-medium content-default text-align-x-left text-wrap",
				Text = if description ~= nil and string.match(description, "%S") ~= nil
					then description
					else `{displayName} has no description.`,
			})
		end

		body = e(ScrollView, {
			tag = "size-full",
			scroll = {
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				CanvasSize = UDim2.fromScale(0, 0),
				ScrollingDirection = Enum.ScrollingDirection.Y,
			},
		}, {
			Pane = e(View, {
				tag = "size-full-0 auto-y col gap-large padding-x-large padding-bottom-large",
				ref = setPane,
			}, {
				Head = e(Head, {
					name = displayName,
					scope = scope,
					registry = registry,
					versionItems = versionItems,
					selectedVersion = version,
					onVersionChanged = setSelectedVersion,
					action = action,
					isWide = breakpoint ~= Breakpoint.XSmall and breakpoint ~= Breakpoint.Small,
					onAuthorActivated = function()
						SearchStore.setQuery(scope)
						Navigation.resetScreen({ name = "Search" })
					end,
					LayoutOrder = nextOrder(),
				}),
				DevAlert = isDev and alert(
					AlertSeverity.Warning,
					`{version} is a dev package, which Discover doesn't install.`,
					nextOrder()
				),
				InstallError = installError ~= nil and alert(AlertSeverity.Error, installError, nextOrder()),
				RemovalError = removal.error ~= nil and alert(AlertSeverity.Error, removal.error, nextOrder()),
				MajorAlert = isMajor and root ~= nil and alert(
					AlertSeverity.Warning,
					`{version} is a major version. Code that uses {rootDisplayName(root, settings)} may need changes.`,
					nextOrder()
				),
				Notice = e(View, {
					tag = "size-full-0 auto-y padding-medium bg-surface-200 radius-medium",
					LayoutOrder = nextOrder(),
				}, {
					Text = e(Text, {
						tag = "size-full-0 auto-y text-body-medium content-default text-align-x-left text-wrap",
						Text = if removal.isRunning then "Removing..." else notice,
						RichText = true,
					}),
				}),
				Facts = e(Facts, {
					facts = facts,
					columns = if breakpoint == Breakpoint.XSmall then 2 else 4,
					LayoutOrder = nextOrder(),
				}),
				Tabs = e(View, {
					tag = "size-full-0 auto-y col gap-medium",
					LayoutOrder = nextOrder(),
				}, {
					Tabs = e(Tabs, {
						activeTabId = tab,
						onActivated = function(id: string | number)
							if id == "versions" or id == "dependencies" or id == "description" then
								setTab(id)
							end
						end,
						tabs = {
							{ id = "description", text = "Description" },
							{ id = "versions", text = "Versions" },
							{
								id = "dependencies",
								text = "Dependencies",
								indicator = if #specs > 0 then { value = #specs } else nil,
							},
						},
						-- Small overflows the 306px minimum, which scrolls Dependencies out of view.
						size = if breakpoint == Breakpoint.XSmall then InputSize.XSmall else InputSize.Medium,
						LayoutOrder = 1,
					}),
					Body = e(View, {
						tag = "size-full-0 auto-y col",
						LayoutOrder = 2,
					}, {
						Content = tabBody,
					}),
				}),
				ConfirmDialog = isConfirming and e(InstallConfirmDialog, {
					request = request,
					onConfirm = function()
						setIsConfirming(false)
						install()
					end,
					onCancel = function()
						setIsConfirming(false)
					end,
				}),
			}),
		})
	end

	return e(Screen, {}, {
		Body = body,
	})
end

return PackageScreen
