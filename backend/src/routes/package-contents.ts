import type { Handler } from "hono";

import type { HonoEnv } from "../types";
import { isValidPackageName, isValidVersion } from "../validation";

const UPSTREAM_ORIGIN = "https://api.wally.run";
const REPO_URL = "github.com/morgann1/studio-discover";
const WALLY_VERSION = "0.3.2";

export const packageContents: Handler<HonoEnv, "/v1/package-contents/:scope/:name/:version"> = async (c) => {
	const scope = c.req.param("scope");
	const name = c.req.param("name");
	const packageVersion = c.req.param("version");

	if (!isValidPackageName(scope) || !isValidPackageName(name) || !isValidVersion(packageVersion)) {
		return c.text("Invalid scope, name, or version", 400);
	}

	const uid = c.get("uid");
	const pluginVersion = c.get("version");

	const upstreamUrl = new URL(`/v1/package-contents/${scope}/${name}/${packageVersion}`, UPSTREAM_ORIGIN);
	const userAgent = `StudioDiscover/${pluginVersion} (+${REPO_URL}; uid=${uid})`;

	let upstream: Response;
	try {
		upstream = await fetch(upstreamUrl, {
			headers: {
				"User-Agent": userAgent,
				"Wally-Version": WALLY_VERSION,
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
