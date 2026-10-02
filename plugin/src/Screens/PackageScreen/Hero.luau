--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const Foundation = require(StudioDiscover.Packages.Foundation)
const React = require(StudioDiscover.Packages.React)

const CompactContext = require(StudioDiscover.Source.Common.CompactContext)
const createNextOrder = require(StudioDiscover.Source.Util.createNextOrder)
const installerTypes = require(StudioDiscover.Source.Installer.types)

const Button = Foundation.Button
const Dropdown = Foundation.Dropdown
const Progress = Foundation.Progress
const Text = Foundation.Text
const View = Foundation.View
const ButtonVariant = Foundation.Enums.ButtonVariant
const InputSize = Foundation.Enums.InputSize
const ProgressShape = Foundation.Enums.ProgressShape
const ProgressSize = Foundation.Enums.ProgressSize

const e = React.createElement

const ACTIONS_WIDTH = 180

-- Joins author names as prose, dropping the "<email>" part a manifest may include.
const function joinAuthors(authors: { string }): string
	const names: { string } = {}
	for _, author in authors do
		const stripped = string.gsub(author, "%s*<[^>]*>%s*", "")
		const trimmed = string.match(stripped, "^%s*(.-)%s*$") or ""
		if trimmed ~= "" then
			table.insert(names, trimmed)
		end
	end

	if #names == 0 then
		return "unknown author"
	elseif #names == 1 then
		return names[1]
	elseif #names == 2 then
		return `{names[1]} and {names[2]}`
	end

	return `{table.concat(names, ", ", 1, #names - 1)}, and {names[#names]}`
end

const function buttonText(status: installerTypes.InstallStatus): string
	if status == "success" then
		return "Installed"
	elseif status == "error" then
		return "Retry"
	end

	return "Install"
end

--[[
	The top of the package screen: name, authors, and description beside the version
		picker and install button. Stacks vertically when the sidebar is compact.
]]
const function Hero(props: {
	read scope: string,
	read name: string,
	read authors: { string },
	read description: string,
	read selectedVersion: string,
	read versionItems: { Foundation.DropdownItem },
	read onVersionChanged: (id: string) -> (),
	read installStatus: installerTypes.InstallStatus,
	read installMessage: string?,
	read isInstallBlocked: boolean,
	read onInstall: () -> (),
	read LayoutOrder: number?,
})
	const compact = CompactContext.useCompact()
	const isRunning = props.installStatus == "running"
	const nextIdentityOrder = createNextOrder()

	const identity: { [string]: React.Node } = {
		Title = e(Text, {
			tag = "size-full-0 auto-y text-title-large content-emphasis text-align-x-left text-wrap",
			Text = `{props.scope}/{props.name}`,
			LayoutOrder = nextIdentityOrder(),
		}),
		Author = e(Text, {
			tag = "size-full-0 auto-y text-body-small content-muted text-align-x-left text-wrap",
			Text = if #props.authors > 0 then `by {joinAuthors(props.authors)}` else `by {props.scope}`,
			LayoutOrder = nextIdentityOrder(),
		}),
		Description = e(Text, {
			tag = "size-full-0 auto-y text-body-medium content-default text-align-x-left text-wrap",
			Text = props.description,
			LayoutOrder = nextIdentityOrder(),
		}),
	}

	const nextActionOrder = createNextOrder()
	const actions = e(View, {
		tag = "size-full-0 auto-y col gap-xsmall",
	}, {
		Dropdown = e(Dropdown.Root, {
			label = "",
			value = props.selectedVersion,
			items = props.versionItems,
			onItemChanged = props.onVersionChanged,
			size = InputSize.Medium,
			width = UDim.new(1, 0),
			maxHeight = 200,
			isDisabled = isRunning,
			LayoutOrder = nextActionOrder(),
		}),
		InstallSlot = e(View, {
			tag = "size-full-0 auto-y row align-y-center",
			LayoutOrder = nextActionOrder(),
		}, {
			Content = if isRunning
				then e(Progress, {
					shape = ProgressShape.Bar,
					size = ProgressSize.Medium,
					width = UDim.new(1, 0),
				})
				else e(Button, {
					text = buttonText(props.installStatus),
					variant = ButtonVariant.Emphasis,
					size = InputSize.Medium,
					width = UDim.new(1, 0),
					isDisabled = props.isInstallBlocked or props.installStatus == "success",
					onActivated = props.onInstall,
				}),
		}),
	})

	const installMessage = props.installMessage
	const status = installMessage ~= nil
		and installMessage ~= ""
		and e(Text, {
			tag = "size-full-0 auto-y text-body-small content-muted text-align-x-left text-truncate",
			Text = installMessage,
		})

	if compact then
		const nextOrder = createNextOrder()

		return e(View, {
			tag = "size-full-0 auto-y col gap-medium padding-large bg-surface-100 radius-medium",
			LayoutOrder = props.LayoutOrder,
		}, {
			Identity = e(View, {
				tag = "size-full-0 auto-y col gap-xsmall",
				LayoutOrder = nextOrder(),
			}, identity),
			Actions = e(View, {
				tag = "size-full-0 auto-y row align-y-center",
				LayoutOrder = nextOrder(),
			}, {
				Content = actions,
			}),
			Status = status and e(View, {
				tag = "size-full-0 auto-y row",
				LayoutOrder = nextOrder(),
			}, {
				Content = status,
			}),
		})
	end

	const nextOrder = createNextOrder()

	return e(View, {
		tag = "size-full-0 auto-y row align-y-top gap-large padding-large bg-surface-100 radius-medium",
		LayoutOrder = props.LayoutOrder,
	}, {
		Left = e(View, {
			tag = "grow auto-y col gap-xsmall",
			LayoutOrder = nextOrder(),
		}, identity),
		Right = e(View, {
			tag = "auto-y col gap-xsmall",
			Size = UDim2.fromOffset(ACTIONS_WIDTH, 0),
			LayoutOrder = nextOrder(),
		}, {
			Actions = actions,
			Status = status,
		}),
	})
end

return Hero
