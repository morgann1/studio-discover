local Discover = script:FindFirstAncestor("Discover")
local Packages = Discover.Packages

local React = require(Packages.React)
local ReactOtter = require(Packages.ReactOtter)

local Settings = require(Discover.Src.Settings.SettingsStore)

local e = React.createElement

local SLIDE_OFFSET = 30
local SPRING_OPTIONS = { frequency = 6, dampingRatio = 1 }

type PageProps = {
	active: boolean,
	component: any,
	pageProps: { [string]: any }?,
	onExited: (() -> ())?,
}

local function Page(props: PageProps)
	local active = props.active
	local onExited = props.onExited
	local reduceMotion = Settings.useSettings().settings.reduceMotion

	local rendered, setRendered = React.useState(active)

	local handleComplete = React.useCallback(function(value)
		if value <= 0 then
			setRendered(false)
			if onExited then
				onExited()
			end
		end
	end, { onExited } :: { any })

	local value, setGoal = ReactOtter.useAnimatedBinding(if active then 1 else 0, handleComplete)

	React.useEffect(function()
		if active then
			setRendered(true)
		end
		if reduceMotion then
			setGoal(ReactOtter.instant(if active then 1 else 0))
			if not active then
				setRendered(false)
				if onExited then
					onExited()
				end
			end
		else
			setGoal(ReactOtter.spring(if active then 1 else 0, SPRING_OPTIONS))
		end
	end, { active, reduceMotion } :: { any })

	if not rendered then
		return nil
	end

	if reduceMotion then
		return e("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
		}, {
			Layout = e("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			Inner = e(props.component, props.pageProps),
		})
	end

	local transparency = value:map(function(v: number)
		return 1 - v
	end)
	local position = value:map(function(v: number)
		local slide = if active then (1 - v) else -(1 - v)
		return UDim2.fromOffset(slide * SLIDE_OFFSET, 0)
	end)

	return e("CanvasGroup", {
		Size = UDim2.fromScale(1, 1),
		Position = position,
		BackgroundTransparency = 1,
		GroupTransparency = transparency,
	}, {
		Layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		Inner = e(props.component, props.pageProps),
	})
end

return Page
