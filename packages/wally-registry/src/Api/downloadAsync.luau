--!strict

const HttpService = game:GetService("HttpService")

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const httpClient = require(StudioDiscover.Libraries.WallyRegistry.Api.httpClient)

-- Downloads one package version's zip archive, or returns nil and why not.
const function downloadAsync(scope: string, name: string, version: string): (string?, string?)
	const encodedScope = HttpService:UrlEncode(scope)
	const encodedName = HttpService:UrlEncode(name)
	const encodedVersion = HttpService:UrlEncode(version)

	const archive, err = httpClient.getAsync(`/package-contents/{encodedScope}/{encodedName}/{encodedVersion}`)

	return archive, err
end

return downloadAsync
