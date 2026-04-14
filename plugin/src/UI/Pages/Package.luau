local Discover = script:FindFirstAncestor("Discover")
local Packages = Discover.Packages

local React = require(Packages.React)

local StubPage = require(Discover.Src.UI.Common.StubPage)

local e = React.createElement

local function Package()
	return e(StubPage, { title = "Package Page" })
end

return Package
