--!strict

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const ServerScriptService = game:GetService("ServerScriptService")

const JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
const describe = JestGlobals.describe
const expect = JestGlobals.expect
const it = JestGlobals.it

const describeHttpFailure = require(ServerScriptService.StudioDiscover.Libraries.Core.describeHttpFailure)

const HOST = "api.wally.run"

describe("describeHttpFailure", function()
	it("reports every engine network error as a failed connection to the host", function()
		for _, message in { "HttpError: ConnectFail", "HttpError: DnsResolve", "HttpError: Timedout" } do
			expect(describeHttpFailure(HOST, { kind = "request", message = message })).toBe(
				"can't connect to api.wally.run"
			)
		end
	end)

	it("passes other request errors through unchanged", function()
		const message = "Number of requests exceeded limit"

		expect(describeHttpFailure(HOST, { kind = "request", message = message })).toBe(message)
	end)

	it("tells server errors apart from refused requests", function()
		expect(describeHttpFailure(HOST, { kind = "status", statusCode = 503 })).toBe(
			"api.wally.run had a server error (HTTP 503)"
		)
		expect(describeHttpFailure(HOST, { kind = "status", statusCode = 403 })).toBe(
			"api.wally.run refused the request (HTTP 403)"
		)
		expect(describeHttpFailure(HOST, { kind = "status", statusCode = 429 })).toBe(
			"api.wally.run is limiting requests, try again in a minute"
		)
	end)
end)
