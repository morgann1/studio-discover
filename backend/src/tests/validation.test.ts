import { describe, expect, it } from "vitest";

import { isValidPackageName, isValidSearchQuery, isValidUid, isValidVersion } from "../validation";

describe("isValidPackageName", () => {
	it("accepts simple lowercase names", () => {
		expect(isValidPackageName("react")).toBe(true);
		expect(isValidPackageName("signal")).toBe(true);
		expect(isValidPackageName("a")).toBe(true);
	});

	it("accepts names with hyphens and digits", () => {
		expect(isValidPackageName("react-roblox")).toBe(true);
		expect(isValidPackageName("v2-package")).toBe(true);
		expect(isValidPackageName("abc123")).toBe(true);
		expect(isValidPackageName("1")).toBe(true);
		expect(isValidPackageName("-")).toBe(true);
	});

	it("rejects empty strings", () => {
		expect(isValidPackageName("")).toBe(false);
	});

	it("rejects uppercase letters", () => {
		expect(isValidPackageName("React")).toBe(false);
		expect(isValidPackageName("REACT")).toBe(false);
		expect(isValidPackageName("reAct")).toBe(false);
	});

	it("rejects any non [a-z0-9-] character", () => {
		expect(isValidPackageName("react_roblox")).toBe(false);
		expect(isValidPackageName("react.roblox")).toBe(false);
		expect(isValidPackageName("react roblox")).toBe(false);
		expect(isValidPackageName("@react")).toBe(false);
		expect(isValidPackageName("react/roblox")).toBe(false);
		expect(isValidPackageName("react\\roblox")).toBe(false);
		expect(isValidPackageName("react:roblox")).toBe(false);
		expect(isValidPackageName("react;rm -rf")).toBe(false);
		expect(isValidPackageName("react+roblox")).toBe(false);
		expect(isValidPackageName("react%20roblox")).toBe(false);
	});

	it("rejects path-traversal shapes", () => {
		expect(isValidPackageName("..")).toBe(false);
		expect(isValidPackageName("../etc")).toBe(false);
		expect(isValidPackageName("..\\windows")).toBe(false);
		expect(isValidPackageName("%2e%2e")).toBe(false);
		expect(isValidPackageName("..%2f")).toBe(false);
	});

	it("rejects control characters and null bytes", () => {
		expect(isValidPackageName("react\0")).toBe(false);
		expect(isValidPackageName("react\n")).toBe(false);
		expect(isValidPackageName("react\r\n")).toBe(false);
		expect(isValidPackageName("react\x7F")).toBe(false);
	});

	it("rejects unicode lookalikes (Cyrillic 'а' is not ASCII 'a')", () => {
		expect(isValidPackageName("re\u0430ct")).toBe(false);
	});

	it("rejects zero-width and BOM characters", () => {
		expect(isValidPackageName("\uFEFFreact")).toBe(false);
		expect(isValidPackageName("re\u200Bact")).toBe(false);
	});

	it("rejects emoji", () => {
		expect(isValidPackageName("react🚀")).toBe(false);
	});

	it("enforces the 64-char cap at the boundary", () => {
		expect(isValidPackageName("a".repeat(63))).toBe(true);
		expect(isValidPackageName("a".repeat(64))).toBe(true);
		expect(isValidPackageName("a".repeat(65))).toBe(false);
		expect(isValidPackageName("a".repeat(1000))).toBe(false);
	});
});

describe("isValidUid", () => {
	it("accepts positive integers", () => {
		expect(isValidUid("1")).toBe(true);
		expect(isValidUid("9")).toBe(true);
		expect(isValidUid("156")).toBe(true);
		expect(isValidUid("9999999999")).toBe(true);
	});

	it("rejects zero (anonymous Studio session)", () => {
		expect(isValidUid("0")).toBe(false);
	});

	it("rejects empty string", () => {
		expect(isValidUid("")).toBe(false);
	});

	it("rejects leading zeros", () => {
		expect(isValidUid("01")).toBe(false);
		expect(isValidUid("007")).toBe(false);
		expect(isValidUid("0000")).toBe(false);
	});

	it("rejects non-digit characters", () => {
		expect(isValidUid("abc")).toBe(false);
		expect(isValidUid("1a")).toBe(false);
		expect(isValidUid("a1")).toBe(false);
		expect(isValidUid("1.5")).toBe(false);
		expect(isValidUid("1e5")).toBe(false);
		expect(isValidUid("0xff")).toBe(false);
		expect(isValidUid("0b11")).toBe(false);
	});

	it("rejects signs and operators", () => {
		expect(isValidUid("-1")).toBe(false);
		expect(isValidUid("+1")).toBe(false);
		expect(isValidUid("1-2")).toBe(false);
		expect(isValidUid("1+2")).toBe(false);
	});

	it("rejects formatted numbers", () => {
		expect(isValidUid("1,234")).toBe(false);
		expect(isValidUid("1_000")).toBe(false);
		expect(isValidUid("1 000")).toBe(false);
	});

	it("rejects whitespace", () => {
		expect(isValidUid(" 1")).toBe(false);
		expect(isValidUid("1 ")).toBe(false);
		expect(isValidUid("\t1")).toBe(false);
		expect(isValidUid("1\n")).toBe(false);
	});

	it("rejects non-ASCII digits", () => {
		// Arabic-Indic digits
		expect(isValidUid("\u0661\u0662\u0663")).toBe(false);
		// Full-width digits
		expect(isValidUid("\uFF11\uFF12\uFF13")).toBe(false);
	});

	it("rejects control characters and null bytes", () => {
		expect(isValidUid("1\0")).toBe(false);
		expect(isValidUid("1\r\n")).toBe(false);
	});

	it("enforces the 20-char cap at the boundary", () => {
		expect(isValidUid("1".repeat(19))).toBe(true);
		expect(isValidUid("1".repeat(20))).toBe(true);
		expect(isValidUid("1".repeat(21))).toBe(false);
		expect(isValidUid("1".repeat(1000))).toBe(false);
	});
});

describe("isValidVersion", () => {
	it("accepts semver-like strings", () => {
		expect(isValidVersion("1.0.0")).toBe(true);
		expect(isValidVersion("2.6.0")).toBe(true);
		expect(isValidVersion("0.1.0")).toBe(true);
		expect(isValidVersion("10.20.30")).toBe(true);
	});

	it("accepts pre-release and build metadata", () => {
		expect(isValidVersion("1.0.0-beta")).toBe(true);
		expect(isValidVersion("1.0.0-beta.1")).toBe(true);
		expect(isValidVersion("1.0.0+build")).toBe(true);
		expect(isValidVersion("1.0.0_rc1")).toBe(true);
		expect(isValidVersion("1.0.0-rc.1+build.123")).toBe(true);
	});

	it("accepts single tokens", () => {
		expect(isValidVersion("1")).toBe(true);
		expect(isValidVersion("main")).toBe(true);
	});

	it("rejects empty string", () => {
		expect(isValidVersion("")).toBe(false);
	});

	it("rejects whitespace anywhere", () => {
		expect(isValidVersion("1.0.0 ")).toBe(false);
		expect(isValidVersion(" 1.0.0")).toBe(false);
		expect(isValidVersion("1.0 .0")).toBe(false);
		expect(isValidVersion("\t1.0.0")).toBe(false);
	});

	it("rejects CRLF header-injection attempts", () => {
		expect(isValidVersion("1.0.0\r\nEvil-Header: x")).toBe(false);
		expect(isValidVersion("1.0.0\n")).toBe(false);
		expect(isValidVersion("1.0.0\r")).toBe(false);
		expect(isValidVersion("1.0.0\r\n\r\n<html>")).toBe(false);
	});

	it("rejects null-byte injection", () => {
		expect(isValidVersion("1.0.0\0evil")).toBe(false);
		expect(isValidVersion("\x001.0.0")).toBe(false);
	});

	it("rejects special characters outside the allowed set", () => {
		expect(isValidVersion("1.0.0@rc")).toBe(false);
		expect(isValidVersion("1.0.0/1")).toBe(false);
		expect(isValidVersion("1.0.0:rc")).toBe(false);
		expect(isValidVersion("1.0.0#sha")).toBe(false);
		expect(isValidVersion("1.0.0$")).toBe(false);
		expect(isValidVersion("1.0.0;")).toBe(false);
	});

	it("rejects unicode", () => {
		expect(isValidVersion("1.0.0-résumé")).toBe(false);
		expect(isValidVersion("1.0.0\u200B")).toBe(false);
	});

	it("enforces the 32-char cap at the boundary", () => {
		expect(isValidVersion("1".repeat(31))).toBe(true);
		expect(isValidVersion("1".repeat(32))).toBe(true);
		expect(isValidVersion("1".repeat(33))).toBe(false);
		expect(isValidVersion("1".repeat(1000))).toBe(false);
	});
});

describe("isValidSearchQuery", () => {
	it("accepts normal queries", () => {
		expect(isValidSearchQuery("react")).toBe(true);
		expect(isValidSearchQuery("react roblox")).toBe(true);
	});

	it("accepts a single character (the 2-char minimum lives in SearchStore)", () => {
		expect(isValidSearchQuery("a")).toBe(true);
	});

	it("accepts special punctuation", () => {
		expect(isValidSearchQuery("foo&bar")).toBe(true);
		expect(isValidSearchQuery("description: ui")).toBe(true);
		expect(isValidSearchQuery("?!#$%^*()")).toBe(true);
		expect(isValidSearchQuery("-._~:/?#[]@!$&'()*+,;=")).toBe(true);
	});

	it("accepts injection-shaped strings (they aren't parsed, just forwarded)", () => {
		expect(isValidSearchQuery("<script>alert(1)</script>")).toBe(true);
		expect(isValidSearchQuery("' OR 1=1 --")).toBe(true);
		expect(isValidSearchQuery("../../etc/passwd")).toBe(true);
	});

	it("accepts unicode", () => {
		expect(isValidSearchQuery("résumé")).toBe(true);
		expect(isValidSearchQuery("日本語")).toBe(true);
		expect(isValidSearchQuery("emoji 🚀")).toBe(true);
	});

	it("rejects empty string", () => {
		expect(isValidSearchQuery("")).toBe(false);
	});

	it("rejects every ASCII control character", () => {
		for (let code = 0; code <= 31; code++) {
			expect(isValidSearchQuery(`foo${String.fromCharCode(code)}bar`)).toBe(false);
		}
		expect(isValidSearchQuery("foo\x7Fbar")).toBe(false);
	});

	it("rejects control chars at boundaries", () => {
		expect(isValidSearchQuery("\nfoo")).toBe(false);
		expect(isValidSearchQuery("foo\r")).toBe(false);
		expect(isValidSearchQuery("\0")).toBe(false);
	});

	it("enforces the 100-char cap at the boundary", () => {
		expect(isValidSearchQuery("a".repeat(99))).toBe(true);
		expect(isValidSearchQuery("a".repeat(100))).toBe(true);
		expect(isValidSearchQuery("a".repeat(101))).toBe(false);
		expect(isValidSearchQuery("a".repeat(10_000))).toBe(false);
	});
});
