import { Hono } from "hono";
import { describe, expect, it } from "vitest";

import { requirePluginHeaders } from "../middleware/require-plugin-headers";
import type { HonoEnv } from "../types";

function makeApp() {
	const app = new Hono<HonoEnv>();
	app.use("*", requirePluginHeaders);
	app.get("/", (c) => c.json({ uid: c.get("uid"), version: c.get("version") }));
	return app;
}

function makeRequest(headers: Record<string, string>): Request {
	return new Request("http://localhost/", { method: "GET", headers });
}

const VALID_HEADERS = {
	"User-Agent": "RobloxStudio/WinInet RobloxApp/0.717.0.7170982",
	"X-Studio-UserId": "12345",
	"X-Plugin-Version": "2.6.0",
};

describe("requirePluginHeaders", () => {
	it("passes valid Studio requests through and stamps variables", async () => {
		const response = await makeApp().fetch(makeRequest(VALID_HEADERS));
		expect(response.status).toBe(200);
		expect(await response.json()).toEqual({ uid: "12345", version: "2.6.0" });
	});

	it("rejects a non-Studio User-Agent with 403", async () => {
		const response = await makeApp().fetch(makeRequest({ ...VALID_HEADERS, "User-Agent": "curl/8.0" }));
		expect(response.status).toBe(403);
	});

	it("rejects a missing User-Agent with 403", async () => {
		const { "User-Agent": _ignored, ...rest } = VALID_HEADERS;
		const response = await makeApp().fetch(makeRequest(rest));
		expect(response.status).toBe(403);
	});

	it("rejects missing X-Studio-UserId with 400", async () => {
		const { "X-Studio-UserId": _ignored, ...rest } = VALID_HEADERS;
		const response = await makeApp().fetch(makeRequest(rest));
		expect(response.status).toBe(400);
	});

	it("rejects missing X-Plugin-Version with 400", async () => {
		const { "X-Plugin-Version": _ignored, ...rest } = VALID_HEADERS;
		const response = await makeApp().fetch(makeRequest(rest));
		expect(response.status).toBe(400);
	});

	it("rejects uid=0 (anonymous) with 400", async () => {
		const response = await makeApp().fetch(makeRequest({ ...VALID_HEADERS, "X-Studio-UserId": "0" }));
		expect(response.status).toBe(400);
	});

	it("rejects non-numeric uid with 400", async () => {
		const response = await makeApp().fetch(makeRequest({ ...VALID_HEADERS, "X-Studio-UserId": "abc" }));
		expect(response.status).toBe(400);
	});

	it("rejects version containing disallowed characters with 400", async () => {
		const response = await makeApp().fetch(makeRequest({ ...VALID_HEADERS, "X-Plugin-Version": "1.0.0 extra" }));
		expect(response.status).toBe(400);
	});

	it("rejects version containing @ (header-injection-adjacent) with 400", async () => {
		const response = await makeApp().fetch(makeRequest({ ...VALID_HEADERS, "X-Plugin-Version": "1.0.0@evil" }));
		expect(response.status).toBe(400);
	});
});
