--!strict

local fmt = require(script.fmt)

export type Logger = {
	debug: (...any) -> (),
	error: (...any) -> (),
	info: (...any) -> (),
	warn: (...any) -> (),
}

local verbose = false

local function setVerbose(value: boolean)
	verbose = value
end

local function createLogger(key: string): Logger
	local function emit(level: string, callback: (string) -> ())
		return function(...: any)
			callback(`[{os.date("%H:%M:%S")}] [{key}] [{level}] {fmt.fmt(...)}`)
		end
	end

	local emitDebug = emit("DEBUG", print)
	local emitInfo = emit("INFO", print)
	local emitWarn = emit("WARN", warn)

	return table.freeze({
		debug = function(...: any)
			if verbose then
				emitDebug(...)
			end
		end,
		info = function(...: any)
			if verbose then
				emitInfo(...)
			end
		end,
		warn = function(...: any)
			if verbose then
				emitWarn(...)
			end
		end,
		-- Logs whether or not verbose logging is on, and never throws, since callers log on their way to cleanup.
		error = emit("ERROR", warn),
	})
end

return table.freeze({
	createLogger = createLogger,
	setVerbose = setVerbose,
})
