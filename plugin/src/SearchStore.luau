local Discover = script:FindFirstAncestor("Discover")
local Packages = Discover.Packages

local Charm = require(Packages.Charm)

local WallyAPI = require(Discover.Src.Api.Wally)

local Search = {}

Search.text = Charm.atom("")
Search.results = Charm.atom({} :: { any })
Search.isLoading = Charm.atom(false)
Search.hasSearched = Charm.atom(false)
Search.error = Charm.atom(nil :: string?)

local searchVersion = 0

function Search.setText(text: string)
	Search.text(text)
end

function Search.clear()
	searchVersion += 1
	Charm.batch(function()
		Search.text("")
		Search.results({})
		Search.isLoading(false)
		Search.hasSearched(false)
		Search.error(nil)
	end)
end

function Search.run(text: string)
	local trimmed = text:match("^%s*(.-)%s*$") or ""

	-- Wally's ngram index tokenizes from 2 chars; single-char queries don't match.
	if #trimmed < 2 then
		Search.clear()
		return
	end

	-- Dedupe: same text already in-flight or last completed successfully.
	if Search.text() == trimmed and Search.hasSearched() and Search.error() == nil then
		return
	end

	text = trimmed

	searchVersion += 1
	local thisVersion = searchVersion

	Charm.batch(function()
		Search.text(text)
		Search.isLoading(true)
		Search.hasSearched(true)
		Search.error(nil)
	end)

	task.spawn(function()
		local data, errorMessage = WallyAPI.search(text)

		if searchVersion ~= thisVersion then
			return
		end

		if not data then
			warn("[Discover] Search failed:", errorMessage)
			Charm.batch(function()
				Search.isLoading(false)
				Search.results({})
				Search.error(tostring(errorMessage) or "Couldn't reach the Wally registry.")
			end)
			return
		end

		for _, result in data do
			if not result.latestVersion and result.versions and result.versions[1] then
				result.latestVersion = result.versions[1]
			end
		end

		Charm.batch(function()
			Search.isLoading(false)
			Search.results(data)
		end)
	end)
end

return Search
