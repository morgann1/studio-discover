import type { MiddlewareHandler } from "hono";

import type { HonoEnv } from "../types";

const CACHE_TTL_SECONDS = 300;

export const edgeCache: MiddlewareHandler<HonoEnv> = async (c, next) => {
	const cache = caches.default;
	const cacheKey = new Request(c.req.url);

	const cached = await cache.match(cacheKey);
	if (cached) {
		return cached;
	}

	await next();

	if (c.res.status === 200) {
		const responseClone = c.res.clone();
		const cacheable = new Response(responseClone.body, responseClone);
		cacheable.headers.set("Cache-Control", `public, max-age=${CACHE_TTL_SECONDS}`);
		c.executionCtx.waitUntil(cache.put(cacheKey, cacheable));
	}
};
