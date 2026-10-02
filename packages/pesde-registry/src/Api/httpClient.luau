--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const createHttpClient = require(StudioDiscover.Libraries.Core.createHttpClient)

const httpClient = createHttpClient("pesde", "https://registry.pesde.daimond113.com/v1", {})

return httpClient
