--!strict

export type Logger = {
	read debug: (message: string) -> (),
	read info: (message: string) -> (),
	read warn: (message: string) -> (),
	read error: (message: string) -> (),
}

local verbose = false

-- Turns debug, info, and warn output on or off for every logger. Error always prints.
const function setVerbose(value: boolean)
	verbose = value
end

--[[
	Returns a logger whose lines carry the time, `key`, and level.

	Messages print as given, so callers interpolate their own values. Error prints
		whether or not verbose logging is on, and never throws, since callers log on
		their way to cleanup.
]]
const function createLogger(key: string): Logger
	const function format(level: string, message: string): string
		return `[{os.date("%H:%M:%S")}] [{key}] [{level}] {message}`
	end

	return table.freeze({
		debug = function(message: string)
			if verbose then
				print(format("DEBUG", message))
			end
		end,
		info = function(message: string)
			if verbose then
				print(format("INFO", message))
			end
		end,
		warn = function(message: string)
			if verbose then
				warn(format("WARN", message))
			end
		end,
		error = function(message: string)
			warn(format("ERROR", message))
		end,
	})
end

const createLoggerModule = table.freeze({
	createLogger = createLogger,
	setVerbose = setVerbose,
})

return createLoggerModule
