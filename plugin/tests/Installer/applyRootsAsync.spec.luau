--!strict

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const ServerScriptService = game:GetService("ServerScriptService")
const Workspace = game:GetService("Workspace")

const JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
const afterEach = JestGlobals.afterEach
const describe = JestGlobals.describe
const expect = JestGlobals.expect
const test = JestGlobals.test

const StudioDiscover = ServerScriptService.StudioDiscover
const applyRootsAsync = require(StudioDiscover.Source.Installer.applyRootsAsync)

const MARKER_NAME = "ApplyRootsAsyncSpecMarker"

-- Stands in for a registry's apply: writes one instance into the place, then returns `failures`.
const function writeMarker(failures: { string }): () -> { string }
	return function()
		const marker = Instance.new("Folder")
		marker.Name = MARKER_NAME
		marker.Parent = Workspace

		return failures
	end
end

afterEach(function()
	const marker = Workspace:FindFirstChild(MARKER_NAME)
	if marker ~= nil then
		marker:Destroy()
	end
end)

describe("applyRootsAsync", function()
	test("keeps the writes and returns the failures when the apply succeeds", function()
		const result = applyRootsAsync("Spec apply", writeMarker({ "a: warning" }))

		expect(result.ok).toBe(true)
		expect(result.failures).toEqual({ "a: warning" })
		expect(Workspace:FindFirstChild(MARKER_NAME)).never.toBeNil()
	end)

	test("undoes the writes and returns a failure when the apply throws", function()
		const result = applyRootsAsync("Spec apply", function(): { string }
			writeMarker({})()
			error("disk on fire", 0)
		end)

		expect(result.ok).toBe(false)
		if not result.ok then
			expect(result.error).toBe("disk on fire")
		end
		expect(Workspace:FindFirstChild(MARKER_NAME)).toBeNil()
	end)

	test("undoes the writes when the root package fails to apply", function()
		const result = applyRootsAsync("Spec apply", writeMarker({ "dep: warning", "root: broken" }), "root:")

		expect(result.ok).toBe(false)
		expect(result.failures).toEqual({ "dep: warning", "root: broken" })
		expect(Workspace:FindFirstChild(MARKER_NAME)).toBeNil()
	end)

	test("keeps the writes when only a dependency fails to apply", function()
		const result = applyRootsAsync("Spec apply", writeMarker({ "dep: warning" }), "root:")

		expect(result.ok).toBe(true)
		expect(Workspace:FindFirstChild(MARKER_NAME)).never.toBeNil()
	end)
end)
