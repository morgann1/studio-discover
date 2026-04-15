local Discover = script:FindFirstAncestor("Discover")
local Packages = Discover.Packages

local React = require(Packages.React)
local StudioComponents = require(Packages.StudioComponents)

local Api = require(Discover.Src.Wally.Api)
local Navigation = require(Discover.Src.UI.Navigation)

local Constants = StudioComponents.Constants
local useTheme = StudioComponents.useTheme

local e = React.createElement
local useEffect = React.useEffect
local useState = React.useState

local TITLE_TEXT_SIZE = 22
local SECTION_HEADER_TEXT_SIZE = 14
local KEY_VALUE_HEIGHT = 18
local DEPENDENCY_ROW_HEIGHT = 22

type FetchState = {
	status: "idle" | "loading" | "ok" | "error",
	data: Api.PackageMetadata?,
	error: string?,
}

type PackageProps = {
	options: {
		scopeName: string?,
		version: string?,
	}?,
}

type ParsedDep = {
	scopeName: string,
	version: string,
}

local function parseDepSpec(spec: string): ParsedDep?
	-- Mirror the wally registry frontend (page.tsx:179):
	-- /(.+\/.+)@[^\d]+([\d.]+)/ — operator(s) then first numeric token.
	local scopeName, version = string.match(spec, "(.+/.+)@[^%d]+([%d%.]+)")
	if not scopeName then
		-- Wally's regex requires an operator, so handle bare specs too.
		scopeName, version = string.match(spec, "(.+/.+)@([%d%.]+)")
	end
	if not scopeName then
		return nil
	end
	return {
		scopeName = scopeName,
		version = version,
	}
end

local function CenteredMessage(props: { text: string })
	local theme = useTheme()
	return e("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, {
		Label = e("TextLabel", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Font = Constants.DefaultFont,
			TextSize = Constants.DefaultTextSize,
			TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.DimmedText),
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
			TextWrapped = true,
			Text = props.text,
		}),
	})
end

local function SectionHeader(props: { text: string, layoutOrder: number })
	local theme = useTheme()
	return e("TextLabel", {
		Text = props.text,
		Font = Enum.Font.SourceSansSemibold,
		TextSize = SECTION_HEADER_TEXT_SIZE,
		TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.SubText),
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 18),
		LayoutOrder = props.layoutOrder,
	})
end

local function KeyValueRow(props: { label: string, value: string, layoutOrder: number })
	local theme = useTheme()
	return e("Frame", {
		Size = UDim2.new(1, 0, 0, KEY_VALUE_HEIGHT),
		BackgroundTransparency = 1,
		LayoutOrder = props.layoutOrder,
	}, {
		Layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 8),
		}),
		Label = e("TextLabel", {
			Text = props.label,
			Font = Constants.DefaultFont,
			TextSize = Constants.DefaultTextSize,
			TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.SubText),
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(80, KEY_VALUE_HEIGHT),
			LayoutOrder = 1,
		}),
		Value = e("TextLabel", {
			Text = props.value,
			Font = Constants.DefaultFont,
			TextSize = Constants.DefaultTextSize,
			TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -88, 0, KEY_VALUE_HEIGHT),
			LayoutOrder = 2,
		}, {
			Flex = e("UIFlexItem", { FlexMode = Enum.UIFlexMode.Fill }),
		}),
	})
end

local KEY_COLUMN_WIDTH = 80
local KEY_COLUMN_GAP = 8

local function AuthorsBlock(props: { authors: { string }, layoutOrder: number })
	local theme = useTheme()

	local children: { [string]: any } = {
		Layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 2),
		}),
		FirstRow = e(KeyValueRow, {
			label = "Authors",
			value = props.authors[1],
			layoutOrder = 1,
		}),
	}

	for index = 2, #props.authors do
		children[`author{index}`] = e("Frame", {
			Size = UDim2.new(1, 0, 0, KEY_VALUE_HEIGHT),
			BackgroundTransparency = 1,
			LayoutOrder = index,
		}, {
			Padding = e("UIPadding", {
				PaddingLeft = UDim.new(0, KEY_COLUMN_WIDTH + KEY_COLUMN_GAP),
			}),
			Value = e("TextLabel", {
				Text = props.authors[index],
				Font = Constants.DefaultFont,
				TextSize = Constants.DefaultTextSize,
				TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText),
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
			}),
		})
	end

	return e("Frame", {
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = props.layoutOrder,
	}, children)
end

local function DependencyRow(props: {
	alias: string,
	spec: string,
	layoutOrder: number,
	onActivated: (() -> ())?,
})
	local theme = useTheme()
	local hovered, setHovered = useState(false)
	local clickable = props.onActivated ~= nil

	local backgroundColor, transparency
	if clickable and hovered then
		backgroundColor = theme:GetColor(Enum.StudioStyleGuideColor.Item, Enum.StudioStyleGuideModifier.Hover)
		transparency = 0
	else
		backgroundColor = theme:GetColor(Enum.StudioStyleGuideColor.Item)
		transparency = 1
	end

	return e("TextButton", {
		Size = UDim2.new(1, 0, 0, DEPENDENCY_ROW_HEIGHT),
		Text = "",
		BackgroundColor3 = backgroundColor,
		BackgroundTransparency = transparency,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		LayoutOrder = props.layoutOrder,
		Active = clickable,
		Selectable = clickable,
		[React.Event.Activated] = props.onActivated,
		[React.Event.MouseEnter] = function()
			setHovered(true)
		end,
		[React.Event.MouseLeave] = function()
			setHovered(false)
		end,
	}, {
		Corner = e("UICorner", { CornerRadius = UDim.new(0, 4) }),
		Padding = e("UIPadding", {
			PaddingLeft = UDim.new(0, 4),
			PaddingRight = UDim.new(0, 4),
		}),
		Layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 8),
		}),
		Alias = e("TextLabel", {
			Text = props.alias,
			Font = Enum.Font.SourceSansSemibold,
			TextSize = Constants.DefaultTextSize,
			TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(120, DEPENDENCY_ROW_HEIGHT),
			LayoutOrder = 1,
		}),
		Spec = e("TextLabel", {
			Text = props.spec,
			Font = Constants.DefaultFont,
			TextSize = Constants.DefaultTextSize,
			TextColor3 = theme:GetColor(
				if clickable then Enum.StudioStyleGuideColor.LinkText else Enum.StudioStyleGuideColor.DimmedText
			),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -128, 0, DEPENDENCY_ROW_HEIGHT),
			LayoutOrder = 2,
		}, {
			Flex = e("UIFlexItem", { FlexMode = Enum.UIFlexMode.Fill }),
		}),
	})
end

local function DependencySection(props: {
	title: string,
	deps: { [string]: string }?,
	layoutOrder: number,
})
	if not props.deps or next(props.deps) == nil then
		return nil
	end

	local children: { [string]: any } = {
		Layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 4),
		}),
		Header = e(SectionHeader, { text = props.title, layoutOrder = 1 }),
	}

	local sorted = {}
	for alias, spec in props.deps do
		table.insert(sorted, { alias = alias, spec = spec })
	end
	table.sort(sorted, function(a, b)
		return a.alias < b.alias
	end)

	for index, dep in sorted do
		local parsed = parseDepSpec(dep.spec)
		local onActivated
		if parsed then
			onActivated = function()
				Navigation.push("Package", {
					scopeName = parsed.scopeName,
					version = parsed.version,
				})
			end
		end
		children[dep.alias] = e(DependencyRow, {
			alias = dep.alias,
			spec = dep.spec,
			layoutOrder = index + 1,
			onActivated = onActivated,
		})
	end

	return e("Frame", {
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = props.layoutOrder,
	}, children)
end

local function PackageContent(props: { metadata: Api.PackageMetadata, requestedVersion: string? })
	local theme = useTheme()
	local versions = props.metadata.versions

	if #versions == 0 then
		return e(CenteredMessage, { text = "No versions returned." })
	end

	local versionStrings = {}
	for index, version in versions do
		versionStrings[index] = version.package.version
	end

	local initialVersion = versionStrings[1]
	if props.requestedVersion then
		for _, v in versionStrings do
			if v == props.requestedVersion then
				initialVersion = props.requestedVersion
				break
			end
		end
	end
	local selectedVersion, setSelectedVersion = useState(initialVersion)

	local selected = versions[1]
	for _, version in versions do
		if version.package.version == selectedVersion then
			selected = version
			break
		end
	end

	local meta = selected.package
	local authors = meta.authors or {}

	return e(StudioComponents.ScrollFrame, {
		Size = UDim2.fromScale(1, 1),
		PaddingLeft = UDim.new(0, 16),
		PaddingRight = UDim.new(0, 16),
		PaddingTop = UDim.new(0, 16),
		PaddingBottom = UDim.new(0, 16),
		Layout = {
			ClassName = "UIListLayout",
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 16),
		},
	}, {
		Hero = e("Frame", {
			Size = UDim2.fromScale(1, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			LayoutOrder = 1,
		}, {
			Layout = e("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 4),
			}),
			Title = e("TextLabel", {
				Text = meta.name,
				Font = Enum.Font.SourceSansBold,
				TextSize = TITLE_TEXT_SIZE,
				TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText),
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, TITLE_TEXT_SIZE + 4),
				LayoutOrder = 1,
			}),
			Version = e("TextLabel", {
				Text = `v{meta.version}`,
				Font = Constants.DefaultFont,
				TextSize = Constants.DefaultTextSize,
				TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.DimmedText),
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 18),
				LayoutOrder = 2,
			}),
			Description = e("TextLabel", {
				Text = meta.description or "(no description)",
				Font = Constants.DefaultFont,
				TextSize = Constants.DefaultTextSize,
				TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText),
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,
				TextWrapped = true,
				BackgroundTransparency = 1,
				AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.fromScale(1, 0),
				LayoutOrder = 3,
			}),
		}),

		Actions = e("Frame", {
			Size = UDim2.new(1, 0, 0, Constants.DefaultButtonHeight),
			BackgroundTransparency = 1,
			LayoutOrder = 2,
		}, {
			Layout = e("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0, 8),
			}),
			Install = e(StudioComponents.MainButton, {
				Text = "Install",
				Size = UDim2.fromOffset(120, Constants.DefaultButtonHeight),
				LayoutOrder = 1,
				Disabled = true,
			}),
			VersionDropdown = e(StudioComponents.Dropdown, {
				Items = versionStrings,
				SelectedItem = selectedVersion,
				Size = UDim2.fromOffset(140, Constants.DefaultDropdownHeight),
				LayoutOrder = 2,
				OnItemSelected = function(newItem: string?)
					if newItem then
						setSelectedVersion(newItem)
					end
				end,
			}),
		}),

		AboutHeader = e(SectionHeader, { text = "About", layoutOrder = 3 }),
		About = e("Frame", {
			Size = UDim2.fromScale(1, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			LayoutOrder = 4,
		}, {
			Layout = e("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 2),
			}),
			License = e(KeyValueRow, {
				label = "License",
				value = meta.license or "Unknown",
				layoutOrder = 1,
			}),
			Realm = e(KeyValueRow, {
				label = "Realm",
				value = meta.realm or "shared",
				layoutOrder = 2,
			}),
			Authors = if #authors > 0
				then e(AuthorsBlock, { authors = authors, layoutOrder = 3 })
				else e(KeyValueRow, { label = "Authors", value = "Unknown", layoutOrder = 3 }),
			Registry = e(KeyValueRow, {
				label = "Registry",
				value = meta.registry,
				layoutOrder = 4,
			}),
		}),

		Dependencies = e(DependencySection, {
			title = "Dependencies",
			deps = selected.dependencies,
			layoutOrder = 5,
		}),
		ServerDependencies = e(DependencySection, {
			title = "Server Dependencies",
			deps = selected["server-dependencies"],
			layoutOrder = 6,
		}),
		DevDependencies = e(DependencySection, {
			title = "Dev Dependencies",
			deps = selected["dev-dependencies"],
			layoutOrder = 7,
		}),
	})
end

local function Package(props: PackageProps)
	local scopeName = props.options and props.options.scopeName
	local state, setState = useState({ status = "idle" } :: FetchState)

	useEffect(function()
		if not scopeName then
			setState({ status = "error", error = "No package name provided." })
			return nil
		end

		local scope, name = string.match(scopeName, "^([^/]+)/(.+)$")
		if not scope then
			setState({ status = "error", error = `Invalid package name: {scopeName}` })
			return nil
		end

		setState({ status = "loading" })

		local cancelled = false
		task.spawn(function()
			local result = Api.getPackageMetadata(scope, name)
			if cancelled then
				return
			end
			if result.ok then
				setState({ status = "ok", data = result.data })
			else
				setState({ status = "error", error = result.error })
			end
		end)

		return function()
			cancelled = true
		end
	end, { scopeName } :: { any })

	if state.status == "loading" then
		return e(CenteredMessage, { text = `Loading {scopeName}...` })
	end
	if state.status == "error" then
		return e(CenteredMessage, { text = `Failed to load {scopeName}: {state.error}` })
	end
	if state.status == "ok" and state.data then
		return e(PackageContent, {
			metadata = state.data,
			requestedVersion = props.options and props.options.version,
		})
	end

	return e(CenteredMessage, { text = "" })
end

return Package
