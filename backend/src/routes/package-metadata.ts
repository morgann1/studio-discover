import type { Handler } from "hono";

import type { HonoEnv } from "../types";
import { isValidPackageName } from "../validation";

const UPSTREAM_ORIGIN = "https://api.wally.run";
const REPO_URL = "github.com/morgann1/studio-discover";

export const packageMetadata: Handler<HonoEnv, "/v1/package-metadata/:scope/:name"> = async (c) => {
	const scope = c.req.param("scope");
	const name = c.req.param("name");
	if (!isValidPackageName(scope) || !isValidPackageName(name)) {
		return c.text("Invalid scope or name", 400);
	}

	const uid = c.get("uid");
	const version = c.get("version");

	const upstreamUrl = new URL(`/v1/package-metadata/${scope}/${name}`, UPSTREAM_ORIGIN);
	const userAgent = `StudioDiscover/${version} (+${REPO_URL}; uid=${uid})`;

	let upstream: Response;
	try {
		upstream = await fetch(upstreamUrl, {
			headers: {
				"User-Agent": userAgent,
				Accept: "application/json",
			},
		});
	} catch {
		return c.text("Upstream unreachable", 502);
	}

	return new Response(upstream.body, {
		status: upstream.status,
		headers: upstream.headers,
	});
};
