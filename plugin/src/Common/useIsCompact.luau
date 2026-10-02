--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const React = require(StudioDiscover.Packages.React)

const COMPACT_THRESHOLD = 600

-- Returns whether `instance` is narrower than the width where the sidebar collapses.
const function useIsCompact(instance: GuiBase2d): boolean
	const isCompact, setIsCompact = React.useState(instance.AbsoluteSize.X < COMPACT_THRESHOLD)

	React.useEffect(function()
		const function update()
			setIsCompact(instance.AbsoluteSize.X < COMPACT_THRESHOLD)
		end

		update()
		const connection = instance:GetPropertyChangedSignal("AbsoluteSize"):Connect(update)

		return function()
			connection:Disconnect()
		end
	end, { instance })

	return isCompact
end

return useIsCompact
