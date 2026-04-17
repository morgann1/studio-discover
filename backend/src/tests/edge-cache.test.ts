import { Hono } from "hono";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

import { edgeCache } from "../middleware/edge-cache";
import type { HonoEnv } from "../types";

type CacheStore = Map<string, Response>;

function stubCaches(store: CacheStore) {
	vi.stubGlobal("caches", {
		default: {
			match: async (req: Request) => {
				const hit = store.get(req.url);
				return hit ? hit.clone() : undefined;
			},
			put: async (req: Request, res: Response) => {
				store.set(req.url, res);
			},
		},
	});
}

function makeCtx() {
	const waits: Promise<unknown>[] = [];
	const ctx: ExecutionContext = {
		waitUntil: (p: Promise<unknown>) => void waits.push(p),
		passThroughOnException: () => {},
		props: {},
	};
	return { ctx, settle: () => Promise.all(waits) };
}

function makeApp(respond: () => Response) {
	const app = new Hono<HonoEnv>();
	app.use("*", edgeCache);
	app.get("/test", () => respond());
	return app;
}

describe("edgeCache", () => {
	let store: CacheStore;

	beforeEach(() => {
		store = new Map();
		stubCaches(store);
	});

	afterEach(() => {
		vi.unstubAllGlobals();
	});

	it("returns the cached response on a hit without invoking the handler", async () => {
		store.set("http://localhost/test", new Response("cached", { status: 200 }));
		const handler = vi.fn(() => new Response("fresh", { status: 200 }));
		const app = makeApp(handler);
		const { ctx } = makeCtx();

		const response = await app.fetch(new Request("http://localhost/test"), {}, ctx);

		expect(await response.text()).toBe("cached");
		expect(handler).not.toHaveBeenCalled();
	});

	it("caches a 200 response on a miss with Cache-Control max-age=300", async () => {
		const app = makeApp(() => new Response("fresh", { status: 200 }));
		const { ctx, settle } = makeCtx();

		await app.fetch(new Request("http://localhost/test"), {}, ctx);
		await settle();

		const cached = store.get("http://localhost/test");
		expect(cached).toBeDefined();
		expect(await cached!.text()).toBe("fresh");
		expect(cached!.headers.get("Cache-Control")).toBe("public, max-age=300");
	});

	it("does not cache non-200 responses", async () => {
		const app = makeApp(() => new Response("nope", { status: 429 }));
		const { ctx, settle } = makeCtx();

		await app.fetch(new Request("http://localhost/test"), {}, ctx);
		await settle();

		expect(store.size).toBe(0);
	});

	it("does not cache upstream errors", async () => {
		const app = makeApp(() => new Response("err", { status: 502 }));
		const { ctx, settle } = makeCtx();

		await app.fetch(new Request("http://localhost/test"), {}, ctx);
		await settle();

		expect(store.size).toBe(0);
	});
});
