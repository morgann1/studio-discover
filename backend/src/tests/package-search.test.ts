import { Hono } from "hono";
import type { MockInstance } from "vitest";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

import { requirePluginHeaders } from "../middleware/require-plugin-headers";
import { packageSearch } from "../routes/package-search";
import type { HonoEnv } from "../types";

function makeApp() {
	const app = new Hono<HonoEnv>();
	app.use("*", requirePluginHeaders);
	app.get("/v1/package-search", packageSearch);
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

describe("packageSearch", () => {
	beforeEach(() => {
		vi.stubGlobal("fetch", vi.fn());
	});

	afterEach(() => {
		vi.unstubAllGlobals();
	});

	it("forwards to api.wally.run with a compliant User-Agent", async () => {
		const fetchMock = vi.mocked(fetch);
		fetchMock.mockResolvedValue(new Response("[]", { status: 200 }));

		await makeApp().fetch(studioRequest("http://localhost/v1/package-search?query=react"));

		const { url, headers } = getFetchArgs(fetchMock);
		expect(url.toString()).toBe("https://api.wally.run/v1/package-search?query=react");
		expect(headers["User-Agent"]).toBe("StudioDiscover/2.6.0 (+github.com/morgann1/studio-discover; uid=12345)");
		expect(headers["Accept"]).toBe("application/json");
	});

	it("returns 400 when the query parameter is missing", async () => {
		const response = await makeApp().fetch(studioRequest("http://localhost/v1/package-search"));
		expect(response.status).toBe(400);
	});

	it("returns 400 when the query parameter is empty", async () => {
		const response = await makeApp().fetch(studioRequest("http://localhost/v1/package-search?query="));
		expect(response.status).toBe(400);
	});

	it("returns 400 when the query contains a control character", async () => {
		const response = await makeApp().fetch(studioRequest("http://localhost/v1/package-search?query=foo%0Abar"));
		expect(response.status).toBe(400);
	});

	it("returns 502 when the upstream fetch throws", async () => {
		vi.mocked(fetch).mockRejectedValue(new Error("network"));
		const response = await makeApp().fetch(studioRequest("http://localhost/v1/package-search?query=react"));
		expect(response.status).toBe(502);
	});

	it("passes upstream status through on non-2xx", async () => {
		vi.mocked(fetch).mockResolvedValue(new Response("not found", { status: 404 }));
		const response = await makeApp().fetch(studioRequest("http://localhost/v1/package-search?query=react"));
		expect(response.status).toBe(404);
		expect(await response.text()).toBe("not found");
	});
});
