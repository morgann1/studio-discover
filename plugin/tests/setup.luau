--!strict

--[[
	Runs before every spec. ReactRoblox only exports `act` under the mock scheduler,
		and React's scheduler reads this flag once, when whichever spec loads React
		first requires it.
]]
_G.__ROACT_17_MOCK_SCHEDULER__ = true

return nil
