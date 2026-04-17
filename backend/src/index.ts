import { Hono } from "hono";

import { requirePluginHeaders } from "./middleware/require-plugin-headers";
import { ghRedirect, packageSearch } from "./routes";
import type { HonoEnv } from "./types";

const app = new Hono<HonoEnv>();

app.get("/", ghRedirect);

app.use("/v1/*", requirePluginHeaders);
app.get("/v1/package-search", packageSearch);

export default app;
