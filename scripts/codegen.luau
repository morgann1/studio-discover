--!strict

--[[
	Regenerates `plugin/generated/` and the sourcemap.

	Usage: lute scripts/codegen.luau
]]

const codegenAsync = require("@scripts/lib/codegenAsync")

codegenAsync({ sourcemap = true })
