--[[
	Charm atoms for search state. Each piece of state is its own atom so
	that components subscribe only to what they read — typing into the
	search box does not re-render the results list, etc.
]]

local Discover = script:FindFirstAncestor("Discover")
local Packages = Discover.Packages

local Charm = require(Packages.Charm)

local WallyAPI = require(Discover.Src.Wally.Api)

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
	if text == "" then
		Search.clear()
		return
	end

	searchVersion += 1
	local thisVersion = searchVersion

	Charm.batch(function()
		Search.text(text)
		Search.isLoading(true)
		Search.hasSearched(true)
		Search.error(nil)
	end)

	task.spawn(function()
		local data, err = WallyAPI.search(text)

		if searchVersion ~= thisVersion then
			return
		end

		if not data then
			warn("[Discover] Search failed:", err)
			Charm.batch(function()
				Search.isLoading(false)
				Search.results({})
				Search.error(tostring(err) or "Couldn't reach the Wally registry.")
			end)
			return
		end

		for _, pkg in data do
			if not pkg.latestVersion and pkg.versions and pkg.versions[1] then
				pkg.latestVersion = pkg.versions[1]
			end
		end

		Charm.batch(function()
			Search.isLoading(false)
			Search.results(data)
		end)
	end)
end

return Search
