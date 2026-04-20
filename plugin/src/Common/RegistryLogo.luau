--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local Foundation = require(StudioDiscover.Packages.Foundation)
local React = require(StudioDiscover.Packages.React)

local types = require(StudioDiscover.Source.Api.types)

local Image = Foundation.Image

local e = React.createElement

type Registry = types.Registry

local LOGOS: { [Registry]: string } = {
	wally = "rbxassetid://87427394631506",
	pesde = "rbxassetid://125159874176259",
}

type Props = {
	registry: Registry,
	width: number?,
	height: number?,
	LayoutOrder: number?,
}

local function RegistryLogo(props: Props)
	local width = props.width or 56
	local height = props.height or 22
	return e(Image, {
		Image = LOGOS[props.registry],
		ScaleType = Enum.ScaleType.Fit,
		Size = UDim2.fromOffset(width, height),
		LayoutOrder = props.LayoutOrder,
	})
end

return RegistryLogo
