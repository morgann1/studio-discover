--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const Foundation = require(StudioDiscover.Packages.Foundation)
const React = require(StudioDiscover.Packages.React)

const Installer = require(StudioDiscover.Source.Installer)
const Navigation = require(StudioDiscover.Source.Navigation)
const RegistryLogo = require(StudioDiscover.Source.Common.RegistryLogo)
const createNextOrder = require(StudioDiscover.Source.Util.createNextOrder)
const coreTypes = require(StudioDiscover.Core.types)
const installerTypes = require(StudioDiscover.Source.Installer.types)

const Button = Foundation.Button
const Progress = Foundation.Progress
const Text = Foundation.Text
const View = Foundation.View
const ButtonVariant = Foundation.Enums.ButtonVariant
const InputSize = Foundation.Enums.InputSize
const ProgressShape = Foundation.Enums.ProgressShape
const ProgressSize = Foundation.Enums.ProgressSize

const e = React.createElement

--[[
	An installed root as a card that opens its package screen, with one action such as
		Remove or Update, shown in the alert style when `isDestructive`. While the action
		runs, a progress bar replaces the button; a failure shows under the card. A
		success needs no handling here, since the installer refreshes the list the row
		came from.
]]
const function RootRow(props: {
	read registry: coreTypes.Registry,
	read scope: string,
	read name: string,
	read meta: string,
	read actionText: string,
	read isDestructive: boolean,
	read runActionAsync: () -> installerTypes.OperationResult,
	read LayoutOrder: number?,
})
	const isRunning, setIsRunning = React.useState(false)
	const errorText, setErrorText = React.useState(nil :: string?)
	const isBusy = Installer.useIsBusy()
	const mountedRef = React.useRef(true)

	React.useEffect(function()
		return function()
			mountedRef.current = false
		end
	end, {})

	const function onView()
		Navigation.pushScreen({
			name = "Package",
			target = {
				registries = { props.registry },
				scope = props.scope,
				name = props.name,
			},
		})
	end

	const function onAction()
		setIsRunning(true)
		setErrorText(nil)

		task.spawn(function()
			const result = props.runActionAsync()
			if not mountedRef.current then
				return
			end

			setIsRunning(false)
			if not result.ok then
				setErrorText(result.error)
			end
		end)
	end

	const nextRootOrder = createNextOrder()
	const nextCardOrder = createNextOrder()
	const nextInfoOrder = createNextOrder()
	const nextSideOrder = createNextOrder()

	return e(View, {
		tag = "size-full-0 auto-y col gap-xsmall",
		LayoutOrder = props.LayoutOrder,
	}, {
		Card = e(View, {
			tag = "size-full-0 auto-y row align-y-center gap-medium padding-medium bg-surface-200 radius-medium",
			onActivated = onView,
			LayoutOrder = nextRootOrder(),
		}, {
			Info = e(View, {
				tag = "grow auto-y col gap-xsmall",
				LayoutOrder = nextCardOrder(),
			}, {
				Title = e(Text, {
					tag = "size-full-0 auto-y text-title-medium content-emphasis text-align-x-left text-wrap",
					Text = `{props.scope}/{props.name}`,
					LayoutOrder = nextInfoOrder(),
				}),
				Meta = e(Text, {
					tag = "size-full-0 auto-y text-body-small content-muted text-align-x-left",
					Text = props.meta,
					LayoutOrder = nextInfoOrder(),
				}),
			}),
			Side = e(View, {
				tag = "auto-xy row align-y-center gap-small",
				LayoutOrder = nextCardOrder(),
			}, {
				Registry = e(RegistryLogo, {
					registry = props.registry,
					LayoutOrder = nextSideOrder(),
				}),
				Action = e(View, {
					tag = "auto-xy row align-y-center",
					LayoutOrder = nextSideOrder(),
				}, {
					Slot = if isRunning
						then e(Progress, {
							shape = ProgressShape.Bar,
							size = ProgressSize.Small,
							width = UDim.new(0, 96),
						})
						else e(Button, {
							text = props.actionText,
							variant = if props.isDestructive then ButtonVariant.Alert else ButtonVariant.Emphasis,
							size = InputSize.Small,
							isDisabled = isBusy,
							onActivated = onAction,
						}),
				}),
			}),
		}),
		Error = errorText ~= nil and e(Text, {
			tag = "size-full-0 auto-y text-body-small content-alert text-align-x-left text-wrap",
			Text = errorText,
			LayoutOrder = nextRootOrder(),
		}),
	})
end

return RootRow
