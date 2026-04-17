--!strict

local Discover = script:FindFirstAncestor("Discover")
local Packages = Discover.Packages

local React = require(Packages.React)
local WallyAPI = require(Discover.Src.Api.Wally)

local function useWallyStatusMessage(): string?
	local message, setMessage = React.useState(WallyAPI.formatWaitMessage(WallyAPI.getStatus()) :: string?)

	React.useEffect(function()
		local cancelled = false
		local tickHandle: thread? = nil

		local function refresh()
			if cancelled then
				return
			end
			local s = WallyAPI.getStatus()
			setMessage(WallyAPI.formatWaitMessage(s))
			if s.state == "waiting" then
				tickHandle = task.delay(0.5, refresh)
			else
				tickHandle = nil
			end
		end

		local unsubscribe = WallyAPI.subscribe(function()
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
