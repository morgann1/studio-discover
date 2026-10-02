--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const Foundation = require(StudioDiscover.Packages.Foundation)
const React = require(StudioDiscover.Packages.React)

const Content = require(StudioDiscover.Source.Common.Content)
const Navigation = require(StudioDiscover.Source.Navigation)
const Screen = require(StudioDiscover.Source.Common.Screen)
const SettingsStore = require(StudioDiscover.Source.SettingsStore)
const createNextOrder = require(StudioDiscover.Source.Util.createNextOrder)

const Row = require(script.Row)

const Button = Foundation.Button
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
	const nextOrder = createNextOrder()
	const children: { [string]: React.Node } = {}

	for index, rule in rules do
		children[`Rule_{index}`] = e(Row, {
			name = rule.name,
			displayName = rule.displayName,
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
			text = "Add entry",
			icon = IconName.Plus,
			variant = ButtonVariant.Utility,
			size = InputSize.Medium,
			onActivated = function()
				addRule(rules)
			end,
		}),
		ClearButton = #rules > 0 and e(Button, {
			text = "Clear all",
			icon = IconName.Trash,
			variant = ButtonVariant.Alert,
			size = InputSize.Medium,
			onActivated = clearRules,
		}),
	})

	return e(Screen, {
		title = "Display Names",
		onBack = Navigation.popScreen,
	}, {
		Body = e(Content, {}, children),
	})
end

return DisplayNamesScreen
