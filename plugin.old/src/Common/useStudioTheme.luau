local Discover = script:FindFirstAncestor("Discover")
local Packages = Discover.Packages

local React = require(Packages.React)

local studio = settings().Studio

local function currentTheme(): "Dark" | "Light"
	return if studio.Theme.Name == "Light" then "Light" else "Dark"
end

local function useStudioTheme(): "Dark" | "Light"
	local theme, setTheme = React.useState(currentTheme)

	React.useEffect(function()
		local connection = studio.ThemeChanged:Connect(function()
			setTheme(currentTheme())
		end)
		return function()
			connection:Disconnect()
		end
	end, {})

	return theme
end

return useStudioTheme
