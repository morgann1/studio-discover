import type { MiddlewareHandler } from "hono";

import type { HonoEnv } from "../types";

const RETRY_AFTER_SECONDS = "10";

export const rateLimit: MiddlewareHandler<HonoEnv> = async (c, next) => {
	const outcome = await c.env.RATE_LIMITER.limit({ key: "global" });
	if (!outcome.success) {
		return c.text("Rate limited", 429, { "Retry-After": RETRY_AFTER_SECONDS });
	}
	await next();
};
