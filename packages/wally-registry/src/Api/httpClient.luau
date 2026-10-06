--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const createHttpClient = require(StudioDiscover.Libraries.Core.createHttpClient)
const isMissing = require(StudioDiscover.Libraries.WallyRegistry.Api.isMissing)

-- The wally CLI version whose API Discover speaks. The registry rejects requests without it.
const WALLY_VERSION = "0.3.2"

const httpClient = createHttpClient("wally", "https://api.wally.run/v1", {
	["Wally-Version"] = WALLY_VERSION,
}, isMissing)

return httpClient
