import type { MiddlewareHandler } from "hono";

import type { HonoEnv } from "../types";

export const requirePluginHeaders: MiddlewareHandler<HonoEnv> = async (c, next) => {
	const uid = c.req.header("X-Studio-UserId");
	const version = c.req.header("X-Plugin-Version");

	if (!uid || !version) {
		return c.text("Missing X-Studio-UserId or X-Plugin-Version", 400);
	}

	c.set("uid", uid);
	c.set("version", version);

	await next();
};
