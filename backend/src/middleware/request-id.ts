import type { MiddlewareHandler } from "hono";

import type { HonoEnv } from "../types";

export const requestId: MiddlewareHandler<HonoEnv> = async (c, next) => {
	const id = c.req.header("CF-Ray") ?? crypto.randomUUID();
	c.set("requestId", id);
	c.header("X-Request-Id", id);
	await next();
};
