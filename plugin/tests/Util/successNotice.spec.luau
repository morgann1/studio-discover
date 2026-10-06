--!strict

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const ServerScriptService = game:GetService("ServerScriptService")

const JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
const describe = JestGlobals.describe
const expect = JestGlobals.expect
const test = JestGlobals.test

const successNotice = require(ServerScriptService.StudioDiscover.Source.Util.successNotice)

describe("successNotice", function()
	test("says what happened, then the hint", function()
		expect(successNotice({ ok = true, failures = {} }, "Removed Promise", "Undo with Ctrl+Z.")).toBe(
			"Removed Promise. Undo with Ctrl+Z."
		)
	end)

	test("counts the warnings of a success", function()
		expect(successNotice({ ok = true, failures = { "a", "b" } }, "Updated 3 packages")).toBe(
			"Updated 3 packages with 2 warnings."
		)
	end)

	test("shows nothing for a failure", function()
		expect(successNotice({ ok = false, error = "offline", failures = {} }, "Removed Promise")).toBeNil()
	end)
end)
