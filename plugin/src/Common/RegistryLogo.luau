--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const Foundation = require(StudioDiscover.Packages.Foundation)
const React = require(StudioDiscover.Packages.React)

const types = require(StudioDiscover.Libraries.Core.types)

const Image = Foundation.Image

const e = React.createElement

const LOGOS: { [types.Registry]: string } = {
	wally = "rbxassetid://87427394631506",
	pesde = "rbxassetid://125159874176259",
}

const function RegistryLogo(props: {
	read registry: types.Registry,
	read LayoutOrder: number?,
})
	return e(Image, {
		Image = LOGOS[props.registry],
		ScaleType = Enum.ScaleType.Fit,
		Size = UDim2.fromOffset(56, 22),
		LayoutOrder = props.LayoutOrder,
	})
end

return RegistryLogo
