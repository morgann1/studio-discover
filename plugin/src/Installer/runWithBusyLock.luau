--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const busyAtom = require(StudioDiscover.Source.Installer.busyAtom)
const createLogger = require(StudioDiscover.Core.createLogger)
const types = require(StudioDiscover.Source.Installer.types)

const logger = createLogger.createLogger("installer.busyLock")

const BUSY_MESSAGE = "Another installer operation is in progress."

--[[
	Runs one installer operation at a time. A call made while another is running is
		rejected without running, and a crash becomes a failed result named after
		`label`, such as "Install failed: ...". `onCrash` sees that message first, so
		an operation can surface it in its own UI state.
]]
const function runWithBusyLock(
	label: string,
	run: () -> types.OperationResult,
	onCrash: ((message: string) -> ())?
): types.OperationResult
	if busyAtom() then
		logger.warn(`{label} rejected: another installer operation is in progress`)

		return {
			ok = false,
			error = BUSY_MESSAGE,
			failures = {},
		}
	end

	busyAtom(true)
	const ok, result = xpcall(run, function(err)
		return `{err}\n{debug.traceback(nil, 2)}`
	end)
	busyAtom(false)

	if ok then
		return result
	end

	const message = `{label} failed: {result}`
	logger.error(message)

	if onCrash ~= nil then
		onCrash(message)
	end

	return {
		ok = false,
		error = message,
		failures = { tostring(result) },
	}
end

return runWithBusyLock
