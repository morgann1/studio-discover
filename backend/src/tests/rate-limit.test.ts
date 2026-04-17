import { Hono } from "hono";
import { describe, expect, it, vi } from "vitest";

import { rateLimit } from "../middleware/rate-limit";
import type { HonoEnv } from "../types";

type MockEnv = {
	RATE_LIMITER: { limit: ReturnType<typeof vi.fn> };
};

function makeApp() {
	const app = new Hono<HonoEnv>();
	app.use("*", rateLimit);
	app.get("/", (c) => c.text("ok"));
	return app;
}

function makeEnv(limitSuccess: boolean): MockEnv {
	return {
		RATE_LIMITER: {
			limit: vi.fn().mockResolvedValue({ success: limitSuccess }),
		},
	};
}

describe("rateLimit", () => {
	it("calls next when the limiter allows", async () => {
		const env = makeEnv(true);
		const response = await makeApp().fetch(new Request("http://localhost/"), env);
		expect(response.status).toBe(200);
		expect(await response.text()).toBe("ok");
	});

	it("returns 429 with Retry-After when the limiter denies", async () => {
		const env = makeEnv(false);
		const response = await makeApp().fetch(new Request("http://localhost/"), env);
		expect(response.status).toBe(429);
		expect(response.headers.get("Retry-After")).toBe("10");
	});

	it("keys on 'global' so all users share the bucket", async () => {
		const env = makeEnv(true);
		await makeApp().fetch(new Request("http://localhost/"), env);
		expect(env.RATE_LIMITER.limit).toHaveBeenCalledWith({ key: "global" });
	});
});
