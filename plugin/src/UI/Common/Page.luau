local Discover = script:FindFirstAncestor("Discover")
local Packages = Discover.Packages

local React = require(Packages.React)
local ReactOtter = require(Packages.ReactOtter)

local e = React.createElement
local useCallback = React.useCallback
local useEffect = React.useEffect
local useState = React.useState

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

	local rendered, setRendered = useState(active)

	local handleComplete = useCallback(function(value: number)
		if value <= 0 then
			setRendered(false)
			if onExited then
				onExited()
			end
		end
	end, { onExited } :: { any })

	local value, setGoal = ReactOtter.useAnimatedBinding(if active then 1 else 0, handleComplete)

	useEffect(function()
		if active then
			setRendered(true)
		end
		setGoal(ReactOtter.spring(if active then 1 else 0, SPRING_OPTIONS))
	end, { active } :: { any })

	if not rendered then
		return nil
	end

	local transparency = value:map(function(v: number): number
		return 1 - v
	end)
	local position = value:map(function(v: number): UDim2
		local slide = if active then (1 - v) else -(1 - v)
		return UDim2.fromOffset(slide * SLIDE_OFFSET, 0)
	end)

	return e("CanvasGroup", {
		Size = UDim2.fromScale(1, 1),
		Position = position,
		BackgroundTransparency = 1,
		GroupTransparency = transparency,
	}, {
		Inner = e(props.component, props.pageProps),
	})
end

return Page
