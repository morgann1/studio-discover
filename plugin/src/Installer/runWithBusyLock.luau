--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local busyAtom = require(StudioDiscover.Source.Installer.busyAtom)

local function runWithBusyLock<T>(onBusy: () -> T, run: () -> T, onError: (string) -> T): T
	if busyAtom() then
		return onBusy()
	end
	busyAtom(true)
	local ok, result = xpcall(run, function(err)
		return tostring(err) .. "\n" .. debug.traceback(nil, 2)
	end)
	busyAtom(false)
	if not ok then
		return onError(tostring(result))
	end
	return result :: T
end

return runWithBusyLock
