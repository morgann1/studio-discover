--!strict

const HttpService = game:GetService("HttpService")

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const createLogger = require(StudioDiscover.Libraries.Core.createLogger)
const httpClient = require(StudioDiscover.Libraries.PesdeRegistry.Api.httpClient)
const types = require(StudioDiscover.Libraries.PesdeRegistry.types)

const logger = createLogger.createLogger("pesde.api.download")

-- Downloads one package version's archive for `target`, or returns nil and why not.
const function downloadAsync(scope: string, name: string, version: string, target: types.Target): (string?, string?)
	const slug = HttpService:UrlEncode(`{scope}/{name}`)
	const path = `/packages/{slug}/{HttpService:UrlEncode(version)}/{HttpService:UrlEncode(target)}/archive`

	const archive, err = httpClient.getAsync(path, { ["Accept"] = "application/octet-stream" })
	if archive == nil then
		return nil, err
	end

	logger.info(`downloaded {scope}/{name}@{version} {target} ({#archive} bytes)`)
	return archive, nil
end

return downloadAsync
