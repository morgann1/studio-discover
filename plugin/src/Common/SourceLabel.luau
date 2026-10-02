--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const Foundation = require(StudioDiscover.Packages.Foundation)
const React = require(StudioDiscover.Packages.React)

const RegistryLogo = require(StudioDiscover.Source.Common.RegistryLogo)
const coreTypes = require(StudioDiscover.Libraries.Core.types)
const registryLabel = require(StudioDiscover.Source.Util.registryLabel)

const Text = Foundation.Text
const View = Foundation.View

const e = React.createElement

-- A source's logo and name, where a row or a by-line says where a package came from.
const function SourceLabel(props: {
	read registry: coreTypes.Registry,
	read isMuted: boolean?,
	read LayoutOrder: number?,
})
	return e(View, {
		tag = "auto-xy row align-y-center gap-small",
		LayoutOrder = props.LayoutOrder,
	}, {
		Logo = e(RegistryLogo, {
			registry = props.registry,
			LayoutOrder = 1,
		}),
		Name = e(Text, {
			tag = {
				["auto-xy text-body-medium"] = true,
				["content-muted"] = props.isMuted == true,
				["content-default"] = props.isMuted ~= true,
			},
			Text = registryLabel(props.registry),
			LayoutOrder = 2,
		}),
	})
end

return SourceLabel
