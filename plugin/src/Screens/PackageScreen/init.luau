--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const Foundation = require(StudioDiscover.Packages.Foundation)
const React = require(StudioDiscover.Packages.React)

const Content = require(StudioDiscover.Source.Common.Content)
const InstallConfirmDialog = require(StudioDiscover.Source.Installer.InstallConfirmDialog)
const Installer = require(StudioDiscover.Source.Installer)
const Navigation = require(StudioDiscover.Source.Navigation)
const Screen = require(StudioDiscover.Source.Common.Screen)
const Section = require(StudioDiscover.Source.Common.Section)
const SettingsStore = require(StudioDiscover.Source.SettingsStore)
const capitalize = require(StudioDiscover.Source.Util.capitalize)
const coreTypes = require(StudioDiscover.Core.types)
const countKeys = require(StudioDiscover.Source.Util.countKeys)
const createNextOrder = require(StudioDiscover.Source.Util.createNextOrder)
const installerTypes = require(StudioDiscover.Source.Installer.types)
const registryLabel = require(StudioDiscover.Source.Util.registryLabel)
const usePackageMetadata = require(StudioDiscover.Source.Api.usePackageMetadata)

const Dependencies = require(script.Dependencies)
const Hero = require(script.Hero)

const Chip = Foundation.Chip
const Empty = Foundation.Empty
const Loading = Foundation.Loading
const Text = Foundation.Text
const View = Foundation.View
const ChipSize = Foundation.Enums.ChipSize

const e = React.createElement

type DependencyGroup = {
	read key: string,
	read title: string,
	read dependencies: coreTypes.DependencyMap,
}

const function findVersion(metadata: coreTypes.PackageMetadata, version: string): coreTypes.PackageVersion
	for _, entry in metadata.versions do
		if entry.package.version == version then
			return entry
		end
	end

	return metadata.versions[1]
end

const function openRegistries()
	Navigation.pushScreen({ name = "Registries" })
end

const function centered(children: { [string]: React.Node }): React.Node
	return e(View, {
		tag = "size-full align-x-center align-y-center padding-large",
	}, children)
end

const function message(text: string): React.Node
	return centered({
		Message = e(Text, {
			tag = "auto-xy text-body-medium content-muted",
			Text = text,
		}),
	})
end

const function aboutRow(label: string, children: { [string]: React.Node }, layoutOrder: number): React.Node
	const nextOrder = createNextOrder()

	return e(View, {
		tag = "size-full-0 auto-y row align-y-center gap-medium",
		LayoutOrder = layoutOrder,
	}, {
		Label = e(Text, {
			tag = "auto-xy text-body-small content-muted",
			Text = `{label}:`,
			LayoutOrder = nextOrder(),
		}),
		Value = e(View, {
			tag = "grow auto-y row align-y-center gap-xsmall",
			LayoutOrder = nextOrder(),
		}, children),
	})
end

const function aboutText(text: string): { [string]: React.Node }
	return {
		Text = e(Text, {
			tag = "size-full-0 auto-y text-body-small content-default text-align-x-left text-truncate",
			Text = text,
		}),
	}
end

--[[
	One package's details, versions, and dependencies, with the install action.
		A package listed by more than one enabled registry gets a chip to switch
		between them.
]]
const function PackageScreen(props: {
	read target: Navigation.PackageTarget,
})
	const target = props.target
	const scope, name = target.scope, target.name

	const settings = SettingsStore.useSettings()
	const installerState = Installer.useInstaller()
	const installedRoots = Installer.useInstalledRoots().roots

	const registries: { coreTypes.Registry } = {}
	for _, registry in target.registries do
		const enabled = if registry == "wally" then settings.registries.wally else settings.registries.pesde
		if enabled then
			table.insert(registries, registry)
		end
	end

	const selectedRegistry, setSelectedRegistry = React.useState(registries[1] or target.registries[1])
	const selectedVersion, setSelectedVersion = React.useState("")
	const isConfirmingInstall, setIsConfirmingInstall = React.useState(false)
	const state = usePackageMetadata(selectedRegistry, scope, name)

	-- Turning a registry off in Settings moves the selection to one that is still on.
	React.useEffect(function()
		if #registries > 0 and table.find(registries, selectedRegistry) == nil then
			setSelectedRegistry(registries[1])
		end
	end, { table.concat(registries, ",") })

	React.useEffect(function()
		const metadata = state.data
		if metadata == nil or #metadata.versions == 0 then
			return
		end

		-- findVersion falls back to the latest when the requested version is not listed.
		setSelectedVersion(findVersion(metadata, target.version or "").package.version)
	end, { state.data, target.version } :: { unknown })

	local body: React.Node
	const metadata = state.data
	if #registries == 0 then
		body = e(Empty, {
			text = "This package's source registries are disabled. Enable them in Settings to install.",
			button = {
				text = "Open Registries",
				onActivated = openRegistries,
			},
		})
	elseif state.loading then
		body = centered({
			Spinner = e(Loading, {}),
		})
	elseif state.error ~= nil then
		body = message(`Couldn't load package: {state.error}`)
	elseif metadata == nil or #metadata.versions == 0 then
		body = message("Package not found.")
	else
		const selected = findVersion(metadata, selectedVersion)
		const pkg = selected.package
		const version = if selectedVersion ~= "" then selectedVersion else pkg.version

		const description = pkg.description
		const descriptionText = if description ~= nil and string.match(description, "%S") ~= nil
			then description
			else `{capitalize(name)} has no provided description.`

		const versionItems: { Foundation.DropdownItem } = {}
		for i, entry in metadata.versions do
			const itemVersion = entry.package.version
			table.insert(versionItems, {
				id = itemVersion,
				text = if i == 1 then `v{itemVersion} (latest)` else `v{itemVersion}`,
			})
		end

		const request: installerTypes.InstallRequest = {
			registry = selectedRegistry,
			scope = scope,
			name = name,
			version = version,
			realm = if pkg.realm == "server" then "server" else "shared",
		}

		const function install()
			task.spawn(Installer.installAsync, request)
		end

		const function onInstall()
			if settings.confirmBeforeInstall then
				setIsConfirmingInstall(true)
			else
				install()
			end
		end

		const function onConfirmInstall()
			setIsConfirmingInstall(false)
			install()
		end

		const function onCancelInstall()
			setIsConfirmingInstall(false)
		end

		-- The installer's state belongs to whichever package it last ran for.
		const installTarget = installerState.target
		const isInstallerTarget = installTarget ~= nil
			and installTarget.scope == scope
			and installTarget.name == name
			and installTarget.version == version

		local isInstalled = false
		for _, root in installedRoots do
			if
				root.registry == selectedRegistry
				and root.scope == scope
				and root.name == name
				and root.version == version
			then
				isInstalled = true
				break
			end
		end

		local installStatus: installerTypes.InstallStatus = "idle"
		local installMessage: string? = nil
		if isInstallerTarget and (installerState.status == "running" or installerState.status == "error") then
			installStatus = installerState.status
			installMessage = installerState.message
		elseif isInstalled then
			installStatus = "success"
		end

		const nextOrder = createNextOrder()
		const nextAboutOrder = createNextOrder()

		const about: { [string]: React.Node } = {
			License = aboutRow("License", aboutText(pkg.license or "Unknown"), nextAboutOrder()),
			Realm = aboutRow("Realm", aboutText(capitalize(pkg.realm)), nextAboutOrder()),
			Versions = aboutRow("Versions", aboutText(tostring(#metadata.versions)), nextAboutOrder()),
		}

		if #registries > 1 then
			const nextChipOrder = createNextOrder()
			const chips: { [string]: React.Node } = {}

			for _, registry in registries do
				chips[registry] = e(Chip, {
					text = registryLabel(registry),
					size = ChipSize.Small,
					isChecked = selectedRegistry == registry,
					onActivated = function()
						setSelectedRegistry(registry)
					end,
					LayoutOrder = nextChipOrder(),
				})
			end

			about.Registry = aboutRow("Registry", chips, nextAboutOrder())
		end

		const children: { [string]: React.Node } = {
			Hero = e(Hero, {
				scope = scope,
				name = name,
				authors = pkg.authors,
				description = descriptionText,
				selectedVersion = version,
				versionItems = versionItems,
				onVersionChanged = setSelectedVersion,
				installStatus = installStatus,
				installMessage = installMessage,
				isInstallBlocked = pkg.realm == "dev",
				onInstall = onInstall,
				LayoutOrder = nextOrder(),
			}),
			About = e(Section, {
				title = "About",
				LayoutOrder = nextOrder(),
			}, about),
			ConfirmInstallDialog = isConfirmingInstall and e(InstallConfirmDialog, {
				request = request,
				onConfirm = onConfirmInstall,
				onCancel = onCancelInstall,
			}),
		}

		const groups: { DependencyGroup } = {
			{ key = "Shared", title = "Shared dependencies", dependencies = selected.dependencies },
			{ key = "Server", title = "Server dependencies", dependencies = selected["server-dependencies"] },
			{ key = "Dev", title = "Dev dependencies", dependencies = selected["dev-dependencies"] },
		}

		for _, group in groups do
			if countKeys(group.dependencies) > 0 then
				children[group.key] = e(Section, {
					title = group.title,
					LayoutOrder = nextOrder(),
				}, {
					List = e(Dependencies, {
						dependencies = group.dependencies,
						registry = selectedRegistry,
					}),
				})
			end
		end

		body = e(Content, {}, children)
	end

	return e(Screen, {
		title = `{scope}/{name}`,
		onBack = Navigation.popScreen,
	}, {
		Body = body,
	})
end

return PackageScreen
