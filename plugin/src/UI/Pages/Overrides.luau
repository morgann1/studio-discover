local Discover = script:FindFirstAncestor("Discover")
local Packages = Discover.Packages

local React = require(Packages.React)

local StubPage = require(Discover.Src.UI.Common.StubPage)

local e = React.createElement

local function Overrides()
	return e(StubPage, { title = "Overrides Page" })
end

return Overrides
