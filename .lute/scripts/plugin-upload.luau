--[[
	Server-side script submitted to Open Cloud's Luau Execution Task API.

	This runs inside a Roblox server (not Lute). It deserializes the rbxm
	sent as the task's binary input and calls AssetService:CreateAssetVersionAsync
	to publish a new version of the Creator Store plugin asset.
]]

local PLUGIN_ID = 91442200339606
local PLUGIN_NAME = "Discover"
local PLUGIN_DESCRIPTION = "Browse and install Luau packages from Wally and pesde directly from Roblox Studio."
local PLUGIN_CREATOR_ID = 48044582
local PLUGIN_CREATOR_TYPE = Enum.AssetCreatorType.User

local args: any = ...
assert(args, "no arguments passed to script")

local input: buffer = args.BinaryInput
assert(input, "no BinaryInput provided")

local AssetService = game:GetService("AssetService")
local EncodingService = game:GetService("EncodingService")
local SerializationService = game:GetService("SerializationService")

local input_hash: buffer = EncodingService:ComputeBufferHash(input, Enum.HashAlgorithm.Sha256)
local hex_hash: { string } = table.create(buffer.len(input_hash))
for i = 0, buffer.len(input_hash) - 1 do
	table.insert(hex_hash, string.format("%02x", buffer.readu8(input_hash, i)))
end

print(`Deserializing plugin (size: {buffer.len(input)} bytes, sha256: {table.concat(hex_hash, "")})`)
local plugin = SerializationService:DeserializeInstancesAsync(input)[1]
assert(plugin, "deserialization returned no instances")

print(`Uploading new version of asset {PLUGIN_ID}`)

local result, version_or_err = AssetService:CreateAssetVersionAsync(plugin, Enum.AssetType.Plugin, PLUGIN_ID, {
	["Name"] = PLUGIN_NAME,
	["Description"] = PLUGIN_DESCRIPTION,
	["CreatorId"] = PLUGIN_CREATOR_ID,
	["CreatorType"] = PLUGIN_CREATOR_TYPE,
})

if result ~= Enum.CreateAssetResult.Success then
	error(`Plugin failed to upload: {result.Name} - {version_or_err}`)
end

print(`Plugin uploaded successfully. New version: {version_or_err}`)
