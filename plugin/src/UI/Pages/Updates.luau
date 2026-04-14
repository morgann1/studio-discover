local Discover = script:FindFirstAncestor("Discover")
local Packages = Discover.Packages

local React = require(Packages.React)

local StubPage = require(Discover.Src.UI.Common.StubPage)

local e = React.createElement

local function Updates()
	return e(StubPage, { title = "Updates will appear here" })
end

return Updates
