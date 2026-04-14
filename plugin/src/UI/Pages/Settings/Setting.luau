local Discover = script:FindFirstAncestor("Discover")
local Packages = Discover.Packages

local Charm = require(Packages.Charm)
local React = require(Packages.React)
local StudioComponents = require(Packages.StudioComponents)

local Settings = require(Discover.Src.UI.Settings)
local lucideIconProps = require(Discover.Src.UI.Common.lucideIconProps)
local useAtom = require(Discover.Src.UI.Common.useAtom)

local Constants = StudioComponents.Constants
local useTheme = StudioComponents.useTheme

local e = React.createElement

-- useAtom must be called unconditionally. For navigation rows that have
-- no associated setting, we feed useAtom this placeholder so the hook
-- call site stays the same shape.
local NULL_ATOM: Charm.Atom<any> = Charm.atom(nil)

type SettingProps = {
	id: string?,
	name: string,
	description: string,
	options: { string }?,
	onNavigate: (() -> ())?,
	layoutOrder: number?,
}

local function Setting(props: SettingProps)
	local atom = if props.id ~= nil then Settings.atoms[props.id] else NULL_ATOM
	local value = useAtom(atom)
	local theme = useTheme()

	local textColor = theme:GetColor(Enum.StudioStyleGuideColor.MainText)
	local dimmedColor = theme:GetColor(Enum.StudioStyleGuideColor.DimmedText)

	local control
	if props.onNavigate then
		control = e(StudioComponents.Button, {
			Icon = lucideIconProps("chevron-right"),
			Size = UDim2.fromOffset(28, 24),
			OnActivated = props.onNavigate,
		})
	elseif props.options then
		control = e(StudioComponents.Dropdown, {
			Items = props.options,
			SelectedItem = value,
			Size = UDim2.fromOffset(140, 20),
			OnItemSelected = function(newItem: string?)
				if newItem and props.id then
					Settings.set(props.id, newItem)
				end
			end,
		})
	else
		control = e(StudioComponents.Checkbox, {
			Value = value,
			Size = UDim2.fromOffset(20, 20),
			OnChanged = function()
				if props.id then
					Settings.set(props.id, not Settings.get(props.id))
				end
			end,
		})
	end

	return e("Frame", {
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = props.layoutOrder,
	}, {
		Padding = e("UIPadding", {
			PaddingTop = UDim.new(0, 10),
			PaddingBottom = UDim.new(0, 10),
		}),
		Row = e("Frame", {
			Size = UDim2.fromScale(1, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
		}, {
			Layout = e("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0, 12),
			}),
			Text = e("Frame", {
				Size = UDim2.fromScale(1, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				LayoutOrder = 1,
			}, {
				Flex = e("UIFlexItem", { FlexMode = Enum.UIFlexMode.Fill }),
				Layout = e("UIListLayout", {
					FillDirection = Enum.FillDirection.Vertical,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 2),
				}),
				Name = e("TextLabel", {
					Text = props.name,
					Font = Constants.DefaultFont,
					TextSize = Constants.DefaultTextSize,
					TextColor3 = textColor,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Top,
					BackgroundTransparency = 1,
					AutomaticSize = Enum.AutomaticSize.Y,
					Size = UDim2.fromScale(1, 0),
					LayoutOrder = 1,
				}),
				Description = e("TextLabel", {
					Text = props.description,
					Font = Constants.DefaultFont,
					TextSize = Constants.DefaultTextSize,
					TextColor3 = dimmedColor,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Top,
					TextWrapped = true,
					BackgroundTransparency = 1,
					AutomaticSize = Enum.AutomaticSize.Y,
					Size = UDim2.fromScale(1, 0),
					LayoutOrder = 2,
				}),
			}),
			ControlWrap = e("Frame", {
				AutomaticSize = Enum.AutomaticSize.XY,
				BackgroundTransparency = 1,
				LayoutOrder = 2,
			}, {
				Inner = control,
			}),
		}),
	})
end

return Setting
