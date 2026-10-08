--!strict

--[[
	Runs inside a Roblox server as an Open Cloud Luau Execution task, submitted by
		`scripts/upload-plugin.luau`. It deserializes the .rbxm sent as the task's
		binary input and publishes it as a new version of the Creator Store plugin.
]]

const AssetService = game:GetService("AssetService")
const EncodingService = game:GetService("EncodingService")
const SerializationService = game:GetService("SerializationService")

const PLUGIN_ID = 124703864101585
const PLUGIN_NAME = "Studio Discover - Install Packages Without a CLI"

-- The Creator Store listing's text. It stays flush left, since a long string keeps its indentation.
const PLUGIN_DESCRIPTION = [[
Studio Discover lets you search Wally, pesde, and Nevermore, and install packages into the place you have open. Dependencies and types come with them.

It does the job of Wally, Rojo, and Rokit from inside Studio. Pick a version, and Discover resolves its dependencies, downloads them, and writes them into your place. No CLI to install, no repository to set up, nothing beyond allowing the permissions Studio asks for.

Features:
- Each install is one undo step, and a failed install changes nothing.
- See which packages have updates, and update one or all of them.
- Remove a package, and the dependencies nothing else needs go with it.
- Pick a naming convention or set your own display names.
- Turn off any registry you don't use.

Source code and release notes are on GitHub (see Social Links).]]
const PLUGIN_CREATOR_ID = 48044582
const PLUGIN_CREATOR_TYPE = Enum.AssetCreatorType.User

-- Luau Execution passes the task's arguments as one table in `...`.
const args: { [string]: unknown }? = ...
assert(args ~= nil, "Expected the task to receive arguments")

const input = args.BinaryInput
assert(typeof(input) == "buffer", "Expected the task's BinaryInput to be a buffer")

const inputHash = EncodingService:ComputeBufferHash(input, Enum.HashAlgorithm.Sha256)
const hexHash = table.create(buffer.len(inputHash))
for index = 0, buffer.len(inputHash) - 1 do
	table.insert(hexHash, string.format("%02x", buffer.readu8(inputHash, index)))
end

print(`Deserializing plugin (size: {buffer.len(input)} bytes, sha256: {table.concat(hexHash)})`)
const plugin = SerializationService:DeserializeInstancesAsync(input)[1]
assert(plugin ~= nil, "Expected the binary input to hold an instance")

print(`Uploading new version of asset {PLUGIN_ID}`)

const result, versionOrError = AssetService:CreateAssetVersionAsync(plugin, Enum.AssetType.Plugin, PLUGIN_ID, {
	Name = PLUGIN_NAME,
	Description = PLUGIN_DESCRIPTION,
	CreatorId = PLUGIN_CREATOR_ID,
	CreatorType = PLUGIN_CREATOR_TYPE,
})

if result ~= Enum.CreateAssetResult.Success then
	error(`Plugin failed to upload: {result.Name} - {versionOrError}`, 0)
end

print(`Plugin uploaded successfully. New version: {versionOrError}`)
