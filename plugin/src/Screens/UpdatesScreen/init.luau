--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const Foundation = require(StudioDiscover.Packages.Foundation)
const React = require(StudioDiscover.Packages.React)

const Content = require(StudioDiscover.Source.Common.Content)
const Installer = require(StudioDiscover.Source.Installer)
const RootRow = require(StudioDiscover.Source.Common.RootRow)
const Screen = require(StudioDiscover.Source.Common.Screen)
const capitalize = require(StudioDiscover.Source.Util.capitalize)
const createNextOrder = require(StudioDiscover.Source.Util.createNextOrder)

const Button = Foundation.Button
const Empty = Foundation.Empty
const Loading = Foundation.Loading
const Text = Foundation.Text
const View = Foundation.View
const ButtonVariant = Foundation.Enums.ButtonVariant
const InputSize = Foundation.Enums.InputSize

const e = React.createElement

-- Lists the installed roots with a newer version, each with its own Update button and one for all.
const function UpdatesScreen()
	const state = Installer.useUpdates()
	const isBusy = Installer.useIsBusy()
	const isUpdatingAll, setIsUpdatingAll = React.useState(false)
	const errorText, setErrorText = React.useState(nil :: string?)
	const mountedRef = React.useRef(true)

	React.useEffect(function()
		return function()
			mountedRef.current = false
		end
	end, {})

	const function onUpdateAll()
		setIsUpdatingAll(true)
		setErrorText(nil)

		task.spawn(function()
			const result = Installer.updateAllAsync(state.updates)
			if not mountedRef.current then
				return
			end

			setIsUpdatingAll(false)
			if not result.ok then
				setErrorText(result.error)
			end
		end)
	end

	local body: React.Node
	if state.loading then
		body = e(View, {
			tag = "size-full align-x-center align-y-center",
		}, {
			Spinner = e(Loading, {}),
		})
	elseif #state.updates == 0 then
		body = e(View, {
			tag = "size-full align-x-center align-y-center",
		}, {
			EmptyState = e(Empty, {
				text = "All packages are up to date",
			}),
		})
	else
		const nextOrder = createNextOrder()
		const children: { [string]: React.Node } = {
			Toolbar = e(View, {
				tag = "size-full-0 auto-y row align-y-center gap-medium",
				LayoutOrder = nextOrder(),
			}, {
				Count = e(Text, {
					tag = "grow auto-y text-body-medium content-muted text-align-x-left",
					Text = `{#state.updates} update(s) available`,
				}),
				UpdateAll = e(Button, {
					text = if isUpdatingAll then "Updating…" else "Update All",
					variant = ButtonVariant.Emphasis,
					size = InputSize.Medium,
					isDisabled = isBusy,
					onActivated = onUpdateAll,
				}),
			}),
			Error = errorText ~= nil and e(Text, {
				tag = "size-full-0 auto-y text-body-small content-alert text-align-x-left text-wrap",
				Text = errorText,
				LayoutOrder = nextOrder(),
			}),
		}

		for _, update in state.updates do
			children[`{update.registry}::{update.realm}::{update.scope}/{update.name}`] = e(RootRow, {
				registry = update.registry,
				scope = update.scope,
				name = update.name,
				meta = `v{update.installedVersion}  →  v{update.latestVersion} · {capitalize(update.realm)}`,
				actionText = "Update",
				isDestructive = false,
				runActionAsync = function()
					return Installer.updateAllAsync({ update })
				end,
				LayoutOrder = nextOrder(),
			})
		end

		body = e(Content, {}, children)
	end

	return e(Screen, { title = "Updates" }, {
		Body = body,
	})
end

return UpdatesScreen
