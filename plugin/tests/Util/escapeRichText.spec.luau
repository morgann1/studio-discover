--!strict

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const ServerScriptService = game:GetService("ServerScriptService")

const JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
const describe = JestGlobals.describe
const expect = JestGlobals.expect
const test = JestGlobals.test

const escapeRichText = require(ServerScriptService.StudioDiscover.Source.Util.escapeRichText)

describe("escapeRichText", function()
	test("escapes markup so a search for a tag shows as text", function()
		expect(escapeRichText("<b>a & b</b>")).toBe("&lt;b&gt;a &amp; b&lt;/b&gt;")
	end)

	test("leaves plain text alone", function()
		expect(escapeRichText("signal")).toBe("signal")
	end)
end)
