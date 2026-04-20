--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local Foundation = require(StudioDiscover.Packages.Foundation)
local React = require(StudioDiscover.Packages.React)

local Content = require(StudioDiscover.Source.Common.Content)
local Navigation = require(StudioDiscover.Source.Navigation)
local Screen = require(StudioDiscover.Source.Common.Screen)
local SettingsStore = require(StudioDiscover.Source.SettingsStore)
local createNextOrder = require(StudioDiscover.Source.Util.createNextOrder)

local Row = require(script.Row)

local Button = Foundation.Button
local View = Foundation.View
local ButtonVariant = Foundation.Enums.ButtonVariant
local IconName = Foundation.Enums.IconName
local InputSize = Foundation.Enums.InputSize

local e = React.createElement

type DisplayNameRule = SettingsStore.DisplayNameRule

local function setRules(rules: { DisplayNameRule })
	SettingsStore.setSetting("displayNames", rules)
end

local function updateName(rules: { DisplayNameRule }, index: number, name: string)
	local next_ = table.clone(rules)
	local rule = table.clone(next_[index])
	rule.name = name
	next_[index] = rule
	setRules(next_)
end

local function updateDisplayName(rules: { DisplayNameRule }, index: number, displayName: string)
	local next_ = table.clone(rules)
	local rule = table.clone(next_[index])
	rule.displayName = displayName
	next_[index] = rule
	setRules(next_)
end

local function removeRule(rules: { DisplayNameRule }, index: number)
	local next_ = table.clone(rules)
	table.remove(next_, index)
	setRules(next_)
end

local function addRule(rules: { DisplayNameRule })
	local next_ = table.clone(rules)
	table.insert(next_, { name = "", displayName = "" })
	setRules(next_)
end

local function DisplayNamesScreen()
	local settings = SettingsStore.useSettings()
	local rules = settings.displayNames

	local onAdd = React.useCallback(function()
		addRule(rules)
	end, { rules } :: { any })

	local onClear = React.useCallback(function()
		setRules({})
	end, {})

	local nextOrder = createNextOrder()
	local children: { [string]: any } = {}

	for index, rule in rules do
		local capturedIndex = index
		children[`Rule_{index}`] = e(Row, {
			name = rule.name,
			displayName = rule.displayName,
			onNameChanged = function(value: string)
				updateName(rules, capturedIndex, value)
			end,
			onDisplayNameChanged = function(value: string)
				updateDisplayName(rules, capturedIndex, value)
			end,
			onRemove = function()
				removeRule(rules, capturedIndex)
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
			onActivated = onAdd,
		}),
		ClearButton = #rules > 0 and e(Button, {
			text = "Clear all",
			icon = IconName.Trash,
			variant = ButtonVariant.Alert,
			size = InputSize.Medium,
			onActivated = onClear,
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
