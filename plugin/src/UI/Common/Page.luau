local Discover = script:FindFirstAncestor("Discover")
local Packages = Discover.Packages

local React = require(Packages.React)
local ReactOtter = require(Packages.ReactOtter)

local Settings = require(Discover.Src.UI.Settings)
local useAtom = require(Discover.Src.UI.Common.useAtom)

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
	local reduceMotion = useAtom(Settings.atoms.reduceMotion)

	local rendered, setRendered = useState(active)

	local handleComplete = useCallback(function(value: number)
		if value <= 0 then
			setRendered(false)
			if onExited then
				onExited()
			end
		end
	end, { onExited } :: { any })

	-- Always start the binding at 0 so a freshly-mounted active page has
	-- distance to spring across; otherwise pushing onto a non-Home page
	-- (e.g. searching from Settings) appears to snap with no transition.
	local value, setGoal = ReactOtter.useAnimatedBinding(0, handleComplete)

	useEffect(function()
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
			Inner = e(props.component, props.pageProps),
		})
	end

	local position = value:map(function(v: number): UDim2
		local slide = if active then (1 - v) else -(1 - v)
		return UDim2.fromOffset(slide * SLIDE_OFFSET, 0)
	end)
	local transparency = value:map(function(v: number): number
		return 1 - v
	end)

	-- Plain Frame instead of CanvasGroup: rojo's Page does the same.
	-- CanvasGroup would re-rasterize the whole subtree every frame of the
	-- spring, which is the main cost on heavy pages like Package. The
	-- transparency binding is threaded through pageProps so individual
	-- leaves can opt into fading without paying the compositing tax.
	local innerProps: { [string]: any } = if props.pageProps then table.clone(props.pageProps) else {}
	innerProps.transparency = transparency

	return e("Frame", {
		Size = UDim2.fromScale(1, 1),
		Position = position,
		BackgroundTransparency = 1,
	}, {
		Inner = e(props.component, innerProps),
	})
end

return Page
