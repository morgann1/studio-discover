import type { MiddlewareHandler } from "hono";

import type { HonoEnv } from "../types";
import { isValidUid, isValidVersion } from "../validation";

const STUDIO_UA_PREFIX = "RobloxStudio/";

export const requirePluginHeaders: MiddlewareHandler<HonoEnv> = async (c, next) => {
	const userAgent = c.req.header("User-Agent") ?? "";
	if (!userAgent.startsWith(STUDIO_UA_PREFIX)) {
		return c.text("This API is only accessible from Roblox Studio", 403);
	}

	const uid = c.req.header("X-Studio-UserId");
	const version = c.req.header("X-Plugin-Version");

	if (!uid || !version) {
		return c.text("Missing X-Studio-UserId or X-Plugin-Version", 400);
	}
	if (!isValidUid(uid)) {
		return c.text("Invalid X-Studio-UserId", 400);
	}
	if (!isValidVersion(version)) {
		return c.text("Invalid X-Plugin-Version", 400);
	}

	c.set("uid", uid);
	c.set("version", version);

	await next();
};
