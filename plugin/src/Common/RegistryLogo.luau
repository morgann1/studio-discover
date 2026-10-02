--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const Foundation = require(StudioDiscover.Packages.Foundation)
const React = require(StudioDiscover.Packages.React)

const registryMark = require(StudioDiscover.Source.Util.registryMark)
const types = require(StudioDiscover.Libraries.Core.types)

const Image = Foundation.Image

const e = React.createElement

-- A registry's square mark, `size` pixels on each side.
const function RegistryLogo(props: {
	read registry: types.Registry,
	read size: number?,
	read LayoutOrder: number?,
})
	const size = props.size or 16

	return e(Image, {
		Image = registryMark(props.registry),
		ScaleType = Enum.ScaleType.Fit,
		Size = UDim2.fromOffset(size, size),
		LayoutOrder = props.LayoutOrder,
	})
end

return RegistryLogo
