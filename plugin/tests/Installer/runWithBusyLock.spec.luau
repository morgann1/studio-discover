--!strict

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const ServerScriptService = game:GetService("ServerScriptService")

const JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
const describe = JestGlobals.describe
const expect = JestGlobals.expect
const test = JestGlobals.test

const StudioDiscover = ServerScriptService.StudioDiscover
const runWithBusyLock = require(StudioDiscover.Source.Installer.runWithBusyLock)

describe("runWithBusyLock", function()
	test("rejects an operation started while another is running", function()
		local inner = nil

		runWithBusyLock("Outer", function()
			inner = runWithBusyLock("Inner", function()
				error("the inner operation must not run")
			end)

			return { ok = true, failures = {} }
		end)

		expect(inner).toEqual({
			ok = false,
			error = "Another installer operation is in progress.",
			failures = {},
		})
	end)

	test("turns a crash into a failed result and releases the lock", function()
		local crashMessage = nil

		const crashed = runWithBusyLock("Install", function()
			error("boom", 0)
		end, function(message)
			crashMessage = message
		end)

		expect(crashed.ok).toBe(false)
		if not crashed.ok then
			expect(crashed.error).toMatch("^Install failed: boom")
			expect(crashMessage).toBe(crashed.error)
		end

		const next = runWithBusyLock("Install", function()
			return { ok = true, failures = {} }
		end)

		expect(next.ok).toBe(true)
	end)
end)
