--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local Foundation = require(StudioDiscover.Packages.Foundation)
local React = require(StudioDiscover.Packages.React)

local Content = require(StudioDiscover.Source.Common.Content)
local Navigation = require(StudioDiscover.Source.Navigation)
local Screen = require(StudioDiscover.Source.Common.Screen)
local changelog = require(StudioDiscover.Generated.changelog)
local createNextOrder = require(StudioDiscover.Source.Util.createNextOrder)
local parseMarkdown = require(StudioDiscover.Source.Util.parseMarkdown)

local Block = require(script.Block)

local Text = Foundation.Text
local View = Foundation.View

local e = React.createElement

local function ChangelogScreen()
	local body: React.ReactNode

	if changelog == "" then
		body = e(View, {
			tag = "size-full align-x-center align-y-center padding-large",
		}, {
			Message = e(Text, {
				tag = "auto-xy text-body-medium content-muted text-align-x-center text-wrap",
				Text = "Changelog not available in this build.",
			}),
		})
	else
		local blocks = parseMarkdown(changelog)
		local nextOrder = createNextOrder()
		local children: { [string]: any } = {}
		for i, block in blocks do
			children[`Block{i}`] = e(Block, {
				block = block,
				LayoutOrder = nextOrder(),
			})
		end
		body = e(Content, {}, children)
	end

	return e(Screen, { title = "Changelog", onBack = Navigation.popScreen }, {
		Body = body,
	})
end

return ChangelogScreen
