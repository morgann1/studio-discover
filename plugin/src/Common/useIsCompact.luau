--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local React = require(StudioDiscover.Packages.React)

local COMPACT_THRESHOLD = 600

-- AbsoluteSize fires every frame during a resize drag; a ref gate ensures
-- React's setState queue is only touched on an actual threshold crossing.
local function useIsCompact(instance: GuiBase2d?): boolean
	local isCompact, setIsCompact = React.useState(true)
	local isCompactRef = React.useRef(true)

	React.useEffect(function(): (() -> ())?
		if instance == nil then
			return nil
		end

		local function update()
			local next_ = instance.AbsoluteSize.X < COMPACT_THRESHOLD
			if next_ == isCompactRef.current then
				return
			end
			isCompactRef.current = next_
			setIsCompact(next_)
		end

		update()
		local connection = instance:GetPropertyChangedSignal("AbsoluteSize"):Connect(update)

		return function()
			connection:Disconnect()
		end
	end, { instance })

	return isCompact
end

return useIsCompact
