--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local Foundation = require(StudioDiscover.Packages.Foundation)
local React = require(StudioDiscover.Packages.React)

local createNextOrder = require(StudioDiscover.Source.Util.createNextOrder)
local parseMarkdown = require(StudioDiscover.Source.Util.parseMarkdown)

local Text = Foundation.Text
local View = Foundation.View

local e = React.createElement

type Props = {
	block: parseMarkdown.Block,
	LayoutOrder: number?,
}

local HEADING_TAGS: { [number]: string } = {
	[1] = "text-title-large content-emphasis",
	[2] = "text-title-medium content-emphasis",
	[3] = "text-title-small content-emphasis",
}

local function Block(props: Props)
	local block = props.block

	if block.kind == "blank" then
		return e(View, {
			tag = "size-full-0 auto-y",
			LayoutOrder = props.LayoutOrder,
			Size = UDim2.new(1, 0, 0, 4),
		})
	end

	if block.kind == "heading" then
		local tag = HEADING_TAGS[block.level or 3] or HEADING_TAGS[3]
		return e(Text, {
			tag = `size-full-0 auto-y {tag} text-align-x-left text-wrap`,
			Text = block.richText,
			RichText = true,
			LayoutOrder = props.LayoutOrder,
		})
	end

	if block.kind == "bullet" then
		local nextOrder = createNextOrder()
		return e(View, {
			tag = "size-full-0 auto-y row align-y-top gap-small",
			LayoutOrder = props.LayoutOrder,
		}, {
			Bullet = e(Text, {
				tag = "auto-xy text-body-medium content-muted",
				Text = "•",
				LayoutOrder = nextOrder(),
			}),
			Body = e(Text, {
				tag = "grow auto-y text-body-medium content-default text-align-x-left text-wrap",
				Text = block.richText,
				RichText = true,
				LayoutOrder = nextOrder(),
			}),
		})
	end

	return e(Text, {
		tag = "size-full-0 auto-y text-body-medium content-default text-align-x-left text-wrap",
		Text = block.richText,
		RichText = true,
		LayoutOrder = props.LayoutOrder,
	})
end

return Block
