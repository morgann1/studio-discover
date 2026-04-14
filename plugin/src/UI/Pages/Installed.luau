local Discover = script:FindFirstAncestor("Discover")
local Packages = Discover.Packages

local React = require(Packages.React)

local StubPage = require(Discover.Src.UI.Common.StubPage)

local e = React.createElement

local function Installed()
	return e(StubPage, { title = "Installed packages will appear here" })
end

return Installed
