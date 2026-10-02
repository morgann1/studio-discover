--!strict

const net = require("@lute/net")

export type Options = {
	read method: ("GET" | "POST" | "PUT")?,
	read headers: { [string]: string }?,
	read body: string?,
}

--[[
	Sends an HTTP request and errors on a non-2xx response, with the response body
		in the message since Open Cloud explains its rejections there.
]]
const function fetchAsync(url: string, options: Options?): net.Response
	const method = if options ~= nil and options.method ~= nil then options.method else "GET"

	const headers = if options ~= nil and options.headers ~= nil then table.clone(options.headers) else {}
	headers["User-Agent"] = "studio-discover-scripts"

	const response = net.client.request(url, {
		method = method,
		headers = headers,
		body = if options ~= nil then options.body else nil,
	})

	if not response.ok then
		error(`{method} {url} failed with HTTP {response.status}: {response.body}`, 0)
	end

	return response
end

return fetchAsync
