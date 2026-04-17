--!strict

local Discover = script:FindFirstAncestor("Discover")
local Packages = Discover.Packages

local React = require(Packages.React)
local WallyStatus = require(Discover.Src.Api.WallyStatus)

local function useWallyStatusMessage(): string?
	local message, setMessage = React.useState(WallyStatus.formatWaitMessage(WallyStatus.get()) :: string?)

	React.useEffect(function()
		local cancelled = false
		local tickHandle: thread? = nil

		local function refresh()
			if cancelled then
				return
			end
			local s = WallyStatus.get()
			setMessage(WallyStatus.formatWaitMessage(s))
			if s.state == "waiting" then
				tickHandle = task.delay(0.5, refresh)
			else
				tickHandle = nil
			end
		end

		local unsubscribe = WallyStatus.subscribe(function()
			refresh()
		end)

		return function()
			cancelled = true
			unsubscribe()
			if tickHandle ~= nil then
				task.cancel(tickHandle)
			end
		end
	end, {})

	return message
end

return useWallyStatusMessage
