import { Hono } from "hono";
import { describe, expect, it, vi } from "vitest";

import { rateLimit } from "../middleware/rate-limit";
import type { HonoEnv } from "../types";

type MockEnv = {
	RATE_LIMITER: { limit: ReturnType<typeof vi.fn> };
	USER_RATE_LIMITER: { limit: ReturnType<typeof vi.fn> };
};

function makeApp() {
	const app = new Hono<HonoEnv>();
	app.use("*", async (c, next) => {
		c.set("uid", "12345");
		await next();
	});
	app.use("*", rateLimit);
	app.get("/", (c) => c.text("ok"));
	return app;
}

function makeEnv(globalSuccess: boolean, userSuccess: boolean): MockEnv {
	return {
		RATE_LIMITER: {
			limit: vi.fn().mockResolvedValue({ success: globalSuccess }),
		},
		USER_RATE_LIMITER: {
			limit: vi.fn().mockResolvedValue({ success: userSuccess }),
		},
	};
}

describe("rateLimit", () => {
	it("calls next when both limiters allow", async () => {
		const env = makeEnv(true, true);
		const response = await makeApp().fetch(new Request("http://localhost/"), env);
		expect(response.status).toBe(200);
		expect(await response.text()).toBe("ok");
	});

	it("returns 429 with Retry-After when the global limiter denies", async () => {
		const env = makeEnv(false, true);
		const response = await makeApp().fetch(new Request("http://localhost/"), env);
		expect(response.status).toBe(429);
		expect(response.headers.get("Retry-After")).toBe("10");
	});

	it("returns 429 with Retry-After when the per-user limiter denies", async () => {
		const env = makeEnv(true, false);
		const response = await makeApp().fetch(new Request("http://localhost/"), env);
		expect(response.status).toBe(429);
		expect(response.headers.get("Retry-After")).toBe("10");
	});

	it("returns 429 when both limiters deny", async () => {
		const env = makeEnv(false, false);
		const response = await makeApp().fetch(new Request("http://localhost/"), env);
		expect(response.status).toBe(429);
	});

	it("keys the global limiter on 'global'", async () => {
		const env = makeEnv(true, true);
		await makeApp().fetch(new Request("http://localhost/"), env);
		expect(env.RATE_LIMITER.limit).toHaveBeenCalledWith({ key: "global" });
	});

	it("keys the per-user limiter on 'uid:<uid>'", async () => {
		const env = makeEnv(true, true);
		await makeApp().fetch(new Request("http://localhost/"), env);
		expect(env.USER_RATE_LIMITER.limit).toHaveBeenCalledWith({ key: "uid:12345" });
	});

	it("checks both limiters in parallel on every request", async () => {
		const env = makeEnv(true, true);
		await makeApp().fetch(new Request("http://localhost/"), env);
		expect(env.RATE_LIMITER.limit).toHaveBeenCalledTimes(1);
		expect(env.USER_RATE_LIMITER.limit).toHaveBeenCalledTimes(1);
	});
});
