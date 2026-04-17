import { Hono } from "hono";
import type { MockInstance } from "vitest";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

import { requirePluginHeaders } from "../middleware/require-plugin-headers";
import { packageContents } from "../routes/package-contents";
import type { HonoEnv } from "../types";

function makeApp() {
	const app = new Hono<HonoEnv>();
	app.use("*", requirePluginHeaders);
	app.get("/v1/package-contents/:scope/:name/:version", packageContents);
	return app;
}

function studioRequest(url: string): Request {
	return new Request(url, {
		headers: {
			"User-Agent": "RobloxStudio/WinInet",
			"X-Studio-UserId": "12345",
			"X-Plugin-Version": "2.6.0",
		},
	});
}

function getFetchArgs(mockedFetch: MockInstance): { url: URL; headers: Record<string, string> } {
	const call = mockedFetch.mock.calls[0] as [URL, RequestInit];
	const init = call[1];
	return { url: call[0], headers: init.headers as Record<string, string> };
}

describe("packageContents", () => {
	beforeEach(() => {
		vi.stubGlobal("fetch", vi.fn());
	});

	afterEach(() => {
		vi.unstubAllGlobals();
	});

	it("forwards to api.wally.run with a compliant User-Agent and Wally-Version", async () => {
		const fetchMock = vi.mocked(fetch);
		fetchMock.mockResolvedValue(new Response(new Uint8Array([0x50, 0x4b]), { status: 200 }));

		await makeApp().fetch(studioRequest("http://localhost/v1/package-contents/jsdotlua/react/17.2.1"));

		const { url, headers } = getFetchArgs(fetchMock);
		expect(url.toString()).toBe("https://api.wally.run/v1/package-contents/jsdotlua/react/17.2.1");
		expect(headers["User-Agent"]).toBe("StudioDiscover/2.6.0 (+github.com/morgann1/studio-discover; uid=12345)");
		expect(headers["Wally-Version"]).toBe("0.3.2");
	});

	it("returns 400 when scope contains uppercase letters", async () => {
		const response = await makeApp().fetch(studioRequest("http://localhost/v1/package-contents/JsDotLua/react/17.2.1"));
		expect(response.status).toBe(400);
	});

	it("returns 400 when name contains disallowed characters", async () => {
		const response = await makeApp().fetch(studioRequest("http://localhost/v1/package-contents/jsdotlua/react_core/17.2.1"));
		expect(response.status).toBe(400);
	});

	it("returns 400 when version contains a disallowed character", async () => {
		const response = await makeApp().fetch(studioRequest("http://localhost/v1/package-contents/jsdotlua/react/17.2.1%20evil"));
		expect(response.status).toBe(400);
	});

	it("returns 502 when the upstream fetch throws", async () => {
		vi.mocked(fetch).mockRejectedValue(new Error("network"));
		const response = await makeApp().fetch(studioRequest("http://localhost/v1/package-contents/jsdotlua/react/17.2.1"));
		expect(response.status).toBe(502);
	});

	it("passes upstream status through on non-2xx", async () => {
		vi.mocked(fetch).mockResolvedValue(new Response("not found", { status: 404 }));
		const response = await makeApp().fetch(studioRequest("http://localhost/v1/package-contents/jsdotlua/react/17.2.1"));
		expect(response.status).toBe(404);
	});
});
