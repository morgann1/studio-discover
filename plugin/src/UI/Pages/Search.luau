local Discover = script:FindFirstAncestor("Discover")
local Packages = Discover.Packages

local React = require(Packages.React)
local StudioComponents = require(Packages.StudioComponents)

local Api = require(Discover.Src.Wally.Api)
local Navigation = require(Discover.Src.UI.Navigation)
local PackageCard = require(Discover.Src.UI.Common.PackageCard)

local Constants = StudioComponents.Constants
local useTheme = StudioComponents.useTheme

local e = React.createElement
local useEffect = React.useEffect
local useState = React.useState

local CARD_HEIGHT = 64
local LIST_PADDING = 8

type FetchState = {
	status: "idle" | "loading" | "ok" | "error",
	results: { Api.SearchResult }?,
	error: string?,
}

type SearchProps = {
	options: {
		query: string?,
	}?,
}

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

local function Search(props: SearchProps)
	local query = props.options and props.options.query or ""
	local trimmedQuery = string.match(query, "^%s*(.-)%s*$") or ""
	local state, setState = useState({ status = "idle" } :: FetchState)

	useEffect(function()
		if trimmedQuery == "" then
			setState({ status = "ok", results = {} })
			return nil
		end

		setState({ status = "loading" })

		local cancelled = false
		task.spawn(function()
			local result = Api.searchPackages(trimmedQuery)
			if cancelled then
				return
			end
			if result.ok then
				setState({ status = "ok", results = result.data })
			else
				setState({ status = "error", error = result.error })
			end
		end)

		return function()
			cancelled = true
		end
	end, { trimmedQuery } :: { any })

	if state.status == "loading" then
		return e(CenteredMessage, { text = `Searching for "{trimmedQuery}"...` })
	end
	if state.status == "error" then
		return e(CenteredMessage, { text = `Search failed: {state.error}` })
	end

	local results = state.results or {}
	if #results == 0 then
		if trimmedQuery == "" then
			return e(CenteredMessage, { text = "Type a query in the search bar to find packages." })
		end
		return e(CenteredMessage, { text = `Nothing found for "{trimmedQuery}"` })
	end

	local cardChildren: { [string]: any } = {
		Layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, LIST_PADDING),
		}),
	}

	for index, result in results do
		local scopeName = `{result.scope}/{result.name}`
		local latestVersion = result.versions[1]
		cardChildren[scopeName] = e("Frame", {
			Size = UDim2.new(1, 0, 0, CARD_HEIGHT),
			BackgroundTransparency = 1,
			LayoutOrder = index,
		}, {
			Card = e(PackageCard, {
				scopeName = scopeName,
				description = result.description,
				layoutOrder = 1,
				onActivated = function()
					Navigation.push("Package", {
						scopeName = scopeName,
						version = latestVersion,
					})
				end,
			}),
		})
	end

	return e(StudioComponents.ScrollFrame, {
		Size = UDim2.fromScale(1, 1),
		PaddingLeft = UDim.new(0, 16),
		PaddingRight = UDim.new(0, 16),
		PaddingTop = UDim.new(0, 16),
		PaddingBottom = UDim.new(0, 16),
		Layout = {
			ClassName = "UIListLayout",
			SortOrder = Enum.SortOrder.LayoutOrder,
		},
	}, {
		List = e("Frame", {
			Size = UDim2.fromScale(1, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			LayoutOrder = 1,
		}, cardChildren),
	})
end

return Search
