--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const createHttpClient = require(StudioDiscover.Core.createHttpClient)

-- The wally CLI version whose API Discover speaks. The registry rejects requests without it.
const WALLY_VERSION = "0.3.2"

const httpClient = createHttpClient("wally", "https://api.wally.run/v1", {
	["Wally-Version"] = WALLY_VERSION,
})

return httpClient
