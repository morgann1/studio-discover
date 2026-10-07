--!strict

const HttpService = game:GetService("HttpService")

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const asString = require(StudioDiscover.Libraries.Core.asString)
const asStringMap = require(StudioDiscover.Libraries.Core.asStringMap)
const asTable = require(StudioDiscover.Libraries.Core.asTable)
const createCache = require(StudioDiscover.Libraries.Core.createCache)
const httpClient = require(StudioDiscover.Libraries.NevermoreRegistry.Api.httpClient)
const packagePath = require(StudioDiscover.Libraries.NevermoreRegistry.Api.packagePath)

-- One published version: its dependencies, by npm name to range, and what the package screen shows about it.
export type VersionDocument = {
	read version: string,
	read dependencies: { [string]: string },
	read description: string?,
	read license: string?,
	read authors: { string },
}

const cache = createCache<<VersionDocument>>()

-- npm writes a person as "Name <email> (url)" or as a table with a name.
const function personName(raw: unknown): string?
	const text = asString(raw)
	if text ~= nil then
		return text:match("^%s*([^<(]-)%s*[<(]") or text
	end

	const person = asTable(raw)
	return if person ~= nil then asString(person.name) else nil
end

-- The package's author, then its contributors, by name.
const function readAuthors(document: asTable.UncheckedTable): { string }
	const authors: { string } = {}

	const author = personName(document.author)
	if author ~= nil and author ~= "" then
		table.insert(authors, author)
	end

	for _, rawContributor in asTable(document.contributors) or {} do
		const contributor = personName(rawContributor)
		if contributor ~= nil and contributor ~= "" and not table.find(authors, contributor) then
			table.insert(authors, contributor)
		end
	end

	return authors
end

--[[
	Fetches one version's document, or returns nil and why not. `version` can also be
		a dist-tag, such as "latest". The third value is true when npm doesn't have the
		package or the version.
]]
const function fetchVersionAsync(name: string, version: string): (VersionDocument?, string?, boolean)
	const path = `{packagePath(name)}/{HttpService:UrlEncode(version)}`

	const cached = cache.get(path)
	if cached ~= nil then
		return cached, nil, false
	end

	const decoded, err, missing = httpClient.getJsonAsync(path)
	if err ~= nil then
		return nil, err, missing
	end

	const document = asTable(decoded)
	if document == nil then
		return nil, "version document is not an object", false
	end

	const resolvedVersion = asString(document.version)
	if resolvedVersion == nil then
		return nil, "version document missing its version", false
	end

	const result: VersionDocument = {
		version = resolvedVersion,
		dependencies = asStringMap(document.dependencies),
		description = asString(document.description),
		license = asString(document.license),
		authors = readAuthors(document),
	}

	cache.set(path, result)
	return result, nil, false
end

return fetchVersionAsync
