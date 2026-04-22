--!strict
-- Publishes StudioDiscover.rbxm to the Roblox Creator Store via rbxasset.
-- Expects rbxasset.toml + rbxasset.lock at cwd, the built .rbxm alongside,
-- and ROBLOX_API_KEY in the environment. Invoked from .github/workflows.

local process = require("@lute/process")

local rbxasset = require("./rbxasset")

local args = process.args
local assetName = args[1]
assert(assetName ~= nil and assetName ~= "", "usage: publish.luau <asset-name>")

local apiKey = process.env.ROBLOX_API_KEY
assert(apiKey ~= nil and apiKey ~= "", "ROBLOX_API_KEY env var is required")

rbxasset.publishPackageAsync(process.cwd(), assetName, apiKey)
