--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const React = require(StudioDiscover.Packages.React)

const registryMark = require(StudioDiscover.Source.Util.registryMark)
const types = require(StudioDiscover.Libraries.Core.types)

const e = React.createElement

--[[
	A registry's square mark, `size` pixels on each side. A native ImageLabel, since
		Foundation's Image doesn't pass the crop through.
]]
const function RegistryLogo(props: {
	read registry: types.Registry,
	read size: number?,
	read LayoutOrder: number?,
})
	const mark = registryMark(props.registry)
	const crop = mark.crop
	const size = props.size or 16

	return e("ImageLabel", {
		Image = mark.image,
		BackgroundTransparency = 1,
		ImageRectOffset = if crop ~= nil then crop.Min else nil,
		ImageRectSize = if crop ~= nil then crop.Max - crop.Min else nil,
		ScaleType = Enum.ScaleType.Fit,
		Size = UDim2.fromOffset(size, size),
		LayoutOrder = props.LayoutOrder,
	})
end

return RegistryLogo
