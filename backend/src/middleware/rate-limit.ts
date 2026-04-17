import type { MiddlewareHandler } from "hono";

import type { HonoEnv } from "../types";

const RETRY_AFTER_SECONDS = "10";

export const rateLimit: MiddlewareHandler<HonoEnv> = async (c, next) => {
	const uid = c.get("uid");

	const [globalResult, userResult] = await Promise.all([
		c.env.RATE_LIMITER.limit({ key: "global" }),
		c.env.USER_RATE_LIMITER.limit({ key: `uid:${uid}` }),
	]);

	if (!globalResult.success || !userResult.success) {
		return c.text("Rate limited", 429, { "Retry-After": RETRY_AFTER_SECONDS });
	}

	await next();
};
