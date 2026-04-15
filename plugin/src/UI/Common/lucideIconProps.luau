local Discover = script:FindFirstAncestor("Discover")
local Packages = Discover.Packages

local Lucide = require(Packages.Lucide)

local DEFAULT_RENDER_SIZE = 16

local function lucideIconProps(name: string, renderSize: number?): { [string]: any }
	local asset = Lucide.GetAsset(name, 48)
	local size = renderSize or DEFAULT_RENDER_SIZE
	return {
		Image = asset.Url,
		Size = Vector2.new(size, size),
		RectOffset = asset.ImageRectOffset,
		RectSize = asset.ImageRectSize,
		UseThemeColor = true,
	}
end

return lucideIconProps
