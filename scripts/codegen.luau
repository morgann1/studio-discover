--!strict

--[[
	Regenerates `plugin/generated/` and the sourcemap.

	Usage: lute scripts/codegen.luau
]]

local codegen = require("@scripts/lib/codegen")

codegen({ sourcemap = true })
