--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const React = require(StudioDiscover.Packages.React)

export type ThemeName = "Dark" | "Light"

const studio = settings().Studio

const function readThemeName(): ThemeName
	return if studio.Theme.Name == "Light" then "Light" else "Dark"
end

-- Returns Studio's current theme, and re-renders when the user switches it.
const function useThemeName(): ThemeName
	const themeName, setThemeName = React.useState(readThemeName())

	React.useEffect(function()
		const connection = studio.ThemeChanged:Connect(function()
			setThemeName(readThemeName())
		end)

		return function()
			connection:Disconnect()
		end
	end, {})

	return themeName
end

return useThemeName
