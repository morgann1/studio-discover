--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const createHttpClient = require(StudioDiscover.Libraries.Core.createHttpClient)

-- npm's registry serves Nevermore. A resolve takes a request per package, so they go four a second.
const httpClient = createHttpClient("nevermore", "https://registry.npmjs.org", {}, nil, 0.25)

return httpClient
