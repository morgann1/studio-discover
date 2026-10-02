--!strict

local net = require("@lute/net")

export type Options = {
	method: ("GET" | "POST" | "PUT")?,
	headers: { [string]: string }?,
	body: string?,
}

--[[
	Sends an HTTP request and errors on a non-2xx response, with the response body
		in the message since Open Cloud explains its rejections there.
]]
local function fetch(url: string, options: Options?): net.Response
	local method = if options ~= nil and options.method ~= nil then options.method else "GET"

	local headers = if options ~= nil and options.headers ~= nil then table.clone(options.headers) else {}
	headers["User-Agent"] = "studio-discover-scripts"

	local response = net.client.request(url, {
		method = method,
		headers = headers,
		body = if options ~= nil then options.body else nil,
	})

	if not response.ok then
		error(`{method} {url} failed with HTTP {response.status}: {response.body}`, 0)
	end

	return response
end

return fetch
