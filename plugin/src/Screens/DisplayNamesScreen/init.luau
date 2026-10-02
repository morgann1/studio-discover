--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const Foundation = require(StudioDiscover.Packages.Foundation)
const React = require(StudioDiscover.Packages.React)

const Content = require(StudioDiscover.Source.Common.Content)
const LayoutContext = require(StudioDiscover.Source.Common.LayoutContext)
const Screen = require(StudioDiscover.Source.Common.Screen)
const SettingsStore = require(StudioDiscover.Source.SettingsStore)
const createNextOrder = require(StudioDiscover.Source.Util.createNextOrder)

const Row = require(script.Row)

const Button = Foundation.Button
const Text = Foundation.Text
const View = Foundation.View
const ButtonVariant = Foundation.Enums.ButtonVariant
const IconName = Foundation.Enums.IconName
const InputSize = Foundation.Enums.InputSize

const e = React.createElement

type DisplayNameRule = SettingsStore.DisplayNameRule

const function setRule(rules: { DisplayNameRule }, index: number, rule: DisplayNameRule)
	const nextRules = table.clone(rules)
	nextRules[index] = rule
	SettingsStore.setSetting("displayNames", nextRules)
end

const function removeRule(rules: { DisplayNameRule }, index: number)
	const nextRules = table.clone(rules)
	table.remove(nextRules, index)
	SettingsStore.setSetting("displayNames", nextRules)
end

const function addRule(rules: { DisplayNameRule })
	const nextRules = table.clone(rules)
	table.insert(nextRules, { name = "", displayName = "" })
	SettingsStore.setSetting("displayNames", nextRules)
end

const function clearRules()
	const noRules: { DisplayNameRule } = {}
	SettingsStore.setSetting("displayNames", noRules)
end

-- Edits the rules that give specific packages a fixed alias when installed.
const function DisplayNamesScreen()
	const rules = SettingsStore.useSettings().displayNames
	const layout = LayoutContext.useLayout()
	const nextOrder = createNextOrder()
	const children: { [string]: React.Node } = {
		Intro = e(Text, {
			tag = "size-full-0 auto-y text-body-medium content-muted text-align-x-left text-wrap",
			Text = "A package listed here installs under its display name instead of a name from the naming convention.",
			LayoutOrder = nextOrder(),
		}),
	}

	for index, rule in rules do
		children[`Rule_{index}`] = e(Row, {
			name = rule.name,
			displayName = rule.displayName,
			isStacked = not layout.isWide,
			onNameChanged = function(name: string)
				setRule(rules, index, { name = name, displayName = rule.displayName })
			end,
			onDisplayNameChanged = function(displayName: string)
				setRule(rules, index, { name = rule.name, displayName = displayName })
			end,
			onRemove = function()
				removeRule(rules, index)
			end,
			LayoutOrder = nextOrder(),
		})
	end

	children.Actions = e(View, {
		tag = "size-full-0 auto-y row align-y-center gap-small",
		LayoutOrder = nextOrder(),
	}, {
		AddButton = e(Button, {
			text = "Add name",
			icon = IconName.PlusSmall,
			variant = ButtonVariant.Standard,
			size = InputSize.Small,
			onActivated = function()
				addRule(rules)
			end,
			LayoutOrder = 1,
		}),
		ClearButton = #rules > 0 and e(Button, {
			text = "Clear all",
			variant = ButtonVariant.Utility,
			size = InputSize.Small,
			onActivated = clearRules,
			LayoutOrder = 2,
		}),
	})

	return e(Screen, {}, {
		Body = e(Content, {}, children),
	})
end

return DisplayNamesScreen
