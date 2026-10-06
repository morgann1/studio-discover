--!strict

--[[
	One way a request to a registry can fail. `request` is an error from `RequestAsync`
		itself, so the registry never answered. `status` is an answer outside 2xx.
]]
export type HttpFailure =
	{
		read kind: "request",
		read message: string,
	}
	| {
		read kind: "status",
		read statusCode: number,
	}
	| {
		read kind: "missing",
	}
	| {
		read kind: "empty",
	}
	| {
		read kind: "unreadable",
	}

--[[
	Says why a request to `host` failed, in words that follow "Couldn't load X:" on
		screen, as in `can't connect to api.wally.run`.

	The engine reports network trouble as `HttpError: <reason>`, such as `ConnectFail`
		or `DnsResolve`, which all mean the same thing to a user. Any other request
		error is already a sentence and passes through.
]]
const function describeHttpFailure(host: string, failure: HttpFailure): string
	if failure.kind == "request" then
		return if string.find(failure.message, "^HttpError") ~= nil then `can't connect to {host}` else failure.message
	elseif failure.kind == "missing" then
		return `not found on {host}`
	elseif failure.kind == "empty" then
		return `{host} sent an empty response`
	elseif failure.kind == "unreadable" then
		return `{host} sent a response Discover can't read`
	end

	const statusCode = failure.statusCode
	if statusCode == 429 then
		return `{host} is limiting requests, try again in a minute`
	elseif statusCode >= 500 then
		return `{host} had a server error (HTTP {statusCode})`
	end

	return `{host} refused the request (HTTP {statusCode})`
end

return describeHttpFailure
