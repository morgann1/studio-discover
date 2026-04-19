--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")
local React = require(StudioDiscover.Packages.React)

export type ThemeName = "Dark" | "Light"

local studio = settings().Studio

local function normalize(name: string): ThemeName
	return if name == "Light" then "Light" else "Dark"
end

local function useThemeName(): ThemeName
	local themeName: ThemeName, setThemeName = React.useState(normalize(studio.Theme.Name) :: ThemeName)

	React.useEffect(function()
		local connection = studio.ThemeChanged:Connect(function()
			setThemeName(normalize(studio.Theme.Name))
		end)
		return function()
			connection:Disconnect()
		end
	end, {})

	return themeName
end

return useThemeName
