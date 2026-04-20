--!strict

local HttpService = game:GetService("HttpService")

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local httpClient = require(StudioDiscover.Source.Api.Wally.httpClient)

local function downloadPackageAsync(scope: string, name: string, version: string): (string?, string?)
	local encodedScope = HttpService:UrlEncode(scope)
	local encodedName = HttpService:UrlEncode(name)
	local encodedVersion = HttpService:UrlEncode(version)
	local path = `/package-contents/{encodedScope}/{encodedName}/{encodedVersion}`
	return httpClient.requestAsync(path)
end

return downloadPackageAsync
