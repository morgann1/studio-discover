import { Hono } from "hono";

import { edgeCache } from "./middleware/edge-cache";
import { rateLimit } from "./middleware/rate-limit";
import { requestId } from "./middleware/request-id";
import { requirePluginHeaders } from "./middleware/require-plugin-headers";
import { ghRedirect, packageMetadata, packageSearch } from "./routes";
import type { HonoEnv } from "./types";

const app = new Hono<HonoEnv>();

app.use("*", requestId);
app.use("/v1/*", requirePluginHeaders);
app.use("/v1/*", edgeCache);
app.use("/v1/*", rateLimit);

app.get("/", ghRedirect);
app.get("/v1/package-search", packageSearch);
app.get("/v1/package-metadata/:scope/:name", packageMetadata);

export default app;
