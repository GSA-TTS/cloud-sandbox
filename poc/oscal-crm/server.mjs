import { createServer } from "node:http";
import { timingSafeEqual } from "node:crypto";
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { digest } from "./model.mjs";
import { createContext, loadContext } from "./context.mjs";
import { createMockBroker } from "./broker.mjs";

function authorized(header, token) {
  const received = Buffer.from(header || "");
  const expected = Buffer.from(`Bearer ${token}`);
  return received.length === expected.length && timingSafeEqual(received, expected);
}
function route(path, tenant, allowedTenant, context) {
  if (path === "/health") return { status: "ok", synthetic: true };
  if (path === "/v2/catalog") return context.catalog();
  if (path === "/api/openapi.json")
    return JSON.parse(readFileSync(new URL("./openapi.json", import.meta.url)));
  if (path === "/api/notes/component-model") {
    return {
      synthetic: true,
      markdown: readFileSync(new URL("./notes/component-model.md", import.meta.url), "utf8"),
    };
  }
  const plan = path.match(/^\/api\/crm\/offerings\/([a-z][a-z0-9-]*)\/plans\/([a-z][a-z0-9-]*)$/);
  if (plan) return context.crm(plan[2], plan[1]);
  const comparison = path.match(/^\/api\/crm\/compare\/([a-z][a-z0-9-]*)\/([a-z][a-z0-9-]*)$/);
  if (comparison) return context.compare(comparison[1], comparison[2]);
  const instance = path.match(/^\/api\/crm\/instances\/([a-z][a-z0-9-]*)$/);
  if (instance) return tenant === allowedTenant ? context.instance(instance[1], tenant) : null;
  if (path.startsWith("/api/components/"))
    return context.component(path.slice("/api/components/".length));
  if (path.startsWith("/api/oscal/")) return context.document(path.slice("/api/oscal/".length));
  return null;
}
export function createApi({
  token,
  brokerToken,
  tenant = "demo-tenant",
  audit = console.log,
  context = createContext(),
} = {}) {
  if (typeof token !== "string" || !/^[A-Za-z0-9_-]{32,128}$/.test(token)) {
    throw new Error("CRM_API_TOKEN must be 32-128 URL-safe characters");
  }
  if (
    brokerToken !== undefined &&
    (typeof brokerToken !== "string" || !/^[A-Za-z0-9_-]{32,128}$/.test(brokerToken))
  )
    throw new Error("MOCK_BROKER_TOKEN must be 32-128 URL-safe characters");
  if (brokerToken === token) throw new Error("MOCK_BROKER_TOKEN must differ from CRM_API_TOKEN");
  if (tenant !== "demo-tenant") throw new Error("Only the synthetic demo-tenant is configured");
  const broker = createMockBroker({ context, audit });
  const server = createServer(async (req, res) => {
    const started = Date.now();
    let routeLabel = "rejected";
    res.on("finish", () =>
      audit(
        JSON.stringify({
          timestamp: new Date().toISOString(),
          agent: "AI-assisted CRM prototype/0.1.0",
          event: "http_request",
          method: req.method,
          route: routeLabel,
          status: res.statusCode,
          duration_ms: Date.now() - started,
        }),
      ),
    );
    const send = (status, body) => {
      res.writeHead(status, {
        "content-type": "application/json; charset=utf-8",
        "cache-control": "no-store",
        "x-content-type-options": "nosniff",
      });
      res.end(JSON.stringify(body));
    };
    const assets = {
      "/": ["viewer/index.html", "text/html; charset=utf-8"],
      "/viewer.mjs": ["viewer/app.mjs", "text/javascript; charset=utf-8"],
      "/viewer.css": ["viewer/style.css", "text/css; charset=utf-8"],
    };
    if (req.method === "GET" && Object.hasOwn(assets, req.url || "")) {
      routeLabel = "viewer";
      const [file, type] = assets[req.url];
      res.writeHead(200, {
        "content-type": type,
        "cache-control": "no-store",
        "x-content-type-options": "nosniff",
        "content-security-policy":
          "default-src 'self'; script-src 'self'; style-src 'self'; connect-src 'self'; frame-ancestors 'none'; base-uri 'none'; form-action 'none'",
      });
      return res.end(readFileSync(new URL(file, import.meta.url)));
    }
    const url = req.url ? new URL(req.url, "http://loopback.invalid") : null;
    const mockPath = url?.pathname || "";
    const brokerRoute =
      /^\/v2\/service_instances\/([a-z][a-z0-9-]*)\/?(?:last_operation)?$/.test(mockPath) ||
      /^\/api\/mock\/service-instances\/([a-z][a-z0-9-]*)\/accounts(?:\/acct-[0-9a-f-]+)?$/.test(
        mockPath,
      );
    const brokerAuthorized = brokerToken && authorized(req.headers.authorization, brokerToken);
    const readBody = () =>
      new Promise((resolve, reject) => {
        let size = 0;
        const chunks = [];
        req.on("data", (chunk) => {
          size += chunk.length;
          if (size > 4096) return reject(new Error("BODY_TOO_LARGE"));
          chunks.push(chunk);
        });
        req.on("end", () => {
          if (!chunks.length) return resolve(null);
          try {
            resolve(JSON.parse(Buffer.concat(chunks).toString("utf8")));
          } catch {
            reject(new Error("INVALID_JSON"));
          }
        });
      });
    if (brokerRoute) {
      if (!brokerAuthorized) {
        res.setHeader("www-authenticate", "Bearer");
        return send(401, {
          error: { code: "UNAUTHORIZED", message: "Broker authentication required" },
        });
      }
      if (url.search || !/^\/[A-Za-z0-9/._-]*$/.test(mockPath))
        return send(400, {
          error: { code: "INVALID_PATH", message: "Use documented paths without query parameters" },
        });
      const instance = mockPath.match(/^\/v2\/service_instances\/([a-z][a-z0-9-]*)$/);
      const lastOperation = mockPath.match(
        /^\/v2\/service_instances\/([a-z][a-z0-9-]*)\/last_operation$/,
      );
      const accounts = mockPath.match(
        /^\/api\/mock\/service-instances\/([a-z][a-z0-9-]*)\/accounts$/,
      );
      const account = mockPath.match(
        /^\/api\/mock\/service-instances\/([a-z][a-z0-9-]*)\/accounts\/(acct-[0-9a-f-]+)$/,
      );
      try {
        const result =
          req.method === "PUT" && instance
            ? broker.provision(instance[1], await readBody())
            : req.method === "GET" && lastOperation
              ? broker.operation(lastOperation[1])
              : req.method === "DELETE" && instance
                ? broker.deprovision(instance[1])
                : req.method === "POST" && accounts
                  ? broker.createAccount(accounts[1], await readBody())
                  : req.method === "GET" && account
                    ? broker.getAccount(account[1], account[2])
                    : null;
        if (!result)
          return send(405, { error: { code: "METHOD_NOT_ALLOWED", message: "Mock broker route" } });
        routeLabel = "mock-broker";
        return send(result.status, result.body);
      } catch (error) {
        const code = error.message === "BODY_TOO_LARGE" ? "BODY_TOO_LARGE" : "INVALID_JSON";
        return send(code === "BODY_TOO_LARGE" ? 413 : 400, {
          error: { code, message: "Invalid request body" },
        });
      }
    }
    if (!authorized(req.headers.authorization, token)) {
      res.setHeader("www-authenticate", "Bearer");
      return send(401, { error: { code: "UNAUTHORIZED", message: "Authentication required" } });
    }
    if (req.method !== "GET")
      return send(405, { error: { code: "METHOD_NOT_ALLOWED", message: "Read-only API" } });
    if (!req.url || req.url.length > 512 || !/^\/[A-Za-z0-9/._-]*$/.test(req.url)) {
      return send(400, {
        error: { code: "INVALID_PATH", message: "Use documented paths without query parameters" },
      });
    }
    try {
      const result = route(req.url, req.headers["x-crm-tenant"], tenant, context);
      routeLabel = result ? req.url : "not-found";
      if (!result) return send(404, { error: { code: "NOT_FOUND", message: "Context not found" } });
      res.setHeader("etag", `"${digest(result)}"`);
      send(200, result);
    } catch (error) {
      audit(
        JSON.stringify({
          timestamp: new Date().toISOString(),
          event: "projection_failure",
          code: "INVALID_SOURCE_CONTEXT",
        }),
      );
      send(500, {
        error: { code: "INVALID_SOURCE_CONTEXT", message: "Source context cannot be projected" },
      });
    }
  });
  server.requestTimeout = 10000;
  server.headersTimeout = 10000;
  server.keepAliveTimeout = 1000;
  server.maxHeadersCount = 30;
  return server;
}
if (process.argv[1] === fileURLToPath(import.meta.url)) {
  const context = process.env.CRM_CONTEXT_MANIFEST
    ? loadContext(process.env.CRM_CONTEXT_MANIFEST)
    : createContext();
  const port = Number(process.env.CRM_API_PORT || 8787);
  if (!Number.isInteger(port) || port < 1024 || port > 65535)
    throw new Error("Invalid CRM_API_PORT");
  const server = createApi({
    token: process.env.CRM_API_TOKEN,
    brokerToken: process.env.MOCK_BROKER_TOKEN,
    context,
  });
  server.on("error", (error) => {
    console.error(`API listener failed: ${error.code || "UNKNOWN"}`);
    process.exitCode = 1;
  });
  server.listen(port, "127.0.0.1", () =>
    console.log(`Synthetic CRM API: http://127.0.0.1:${port}`),
  );
  for (const signal of ["SIGINT", "SIGTERM"]) process.on(signal, () => server.close());
}
