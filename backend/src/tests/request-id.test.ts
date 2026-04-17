import { Hono } from "hono";
import { describe, expect, it } from "vitest";

import { requestId } from "../middleware/request-id";
import type { HonoEnv } from "../types";

const UUID_PATTERN = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

function makeApp() {
	const app = new Hono<HonoEnv>();
	app.use("*", requestId);
	app.get("/", (c) => c.text(c.get("requestId")));
	return app;
}

describe("requestId", () => {
	it("echoes CF-Ray as X-Request-Id when present", async () => {
		const response = await makeApp().fetch(
			new Request("http://localhost/", {
				headers: { "CF-Ray": "abc123-SJC" },
			}),
		);
		expect(response.headers.get("X-Request-Id")).toBe("abc123-SJC");
	});

	it("generates a UUID when CF-Ray is absent", async () => {
		const response = await makeApp().fetch(new Request("http://localhost/"));
		const id = response.headers.get("X-Request-Id");
		expect(id).toMatch(UUID_PATTERN);
	});

	it("exposes the id to downstream handlers via c.get('requestId')", async () => {
		const response = await makeApp().fetch(
			new Request("http://localhost/", {
				headers: { "CF-Ray": "trace-42" },
			}),
		);
		expect(await response.text()).toBe("trace-42");
	});

	it("generates a fresh UUID per request without CF-Ray", async () => {
		const app = makeApp();
		const first = await app.fetch(new Request("http://localhost/"));
		const second = await app.fetch(new Request("http://localhost/"));
		expect(first.headers.get("X-Request-Id")).not.toBe(second.headers.get("X-Request-Id"));
	});
});
