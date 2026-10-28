import { test } from "node:test";
import assert from "node:assert/strict";
import { createServer } from "node:http";
import { randomBytes } from "node:crypto";
import { createApi } from "../server.mjs";
import { createContext } from "../context.mjs";
import { dispatchCall, queueCall, schedulerReference } from "../scheduler/contract-mock.mjs";
import { createTriggerAdapter } from "../scheduler/adapter.mjs";
import { crmForPlan } from "../model.mjs";

const secret = () => randomBytes(32).toString("hex");
async function listen(t, server) {
  await new Promise((resolve, reject) => {
    server.once("error", reject);
    server.listen(0, "127.0.0.1", resolve);
  });
  t.after(
    () =>
      new Promise((resolve) => {
        server.closeAllConnections();
        server.close(resolve);
      }),
  );
  return `http://127.0.0.1:${server.address().port}`;
}
async function setup(t, options = {}) {
  const crmToken = secret(),
    triggerToken = secret(),
    logs = [];
  const crmBase = await listen(t, createApi({ token: crmToken, audit: (line) => logs.push(line) }));
  const adapter = await listen(
    t,
    createTriggerAdapter({
      crmBase,
      crmToken,
      triggerToken,
      audit: (line) => logs.push(line),
      ...options,
    }),
  );
  return { crmBase, adapter, crmToken, triggerToken, logs };
}
test("scheduler contract reference is pinned and direct POST to read-only CRM returns 405", async (t) => {
  assert.equal(schedulerReference.revision.length, 40);
  const { crmBase, crmToken } = await setup(t);
  const execution = await dispatchCall({
    url: `${crmBase}/api/crm/offerings/managed-hosting/plans/managed`,
    authHeader: `Bearer ${crmToken}`,
  });
  assert.equal(execution.http_status, 405);
  assert.equal(execution.state, "FAILED");
});
test("mock dispatch forwards authorization, empty POST and no tenant header", async (t) => {
  const auth = `Bearer ${secret()}`;
  const requests = [];
  const base = await listen(
    t,
    createServer(async (req, res) => {
      let bytes = 0;
      for await (const chunk of req) bytes += chunk.length;
      requests.push({
        method: req.method,
        authorization: req.headers.authorization,
        tenant: req.headers["x-crm-tenant"],
        bytes,
      });
      res.end();
    }),
  );
  assert.equal((await dispatchCall({ url: base, authHeader: auth })).state, "SUCCEEDED");
  assert.deepEqual(requests, [
    { method: "POST", authorization: auth, tenant: undefined, bytes: 0 },
  ]);
});
test("start recording failure skips target and transient failure dispatches exactly once", async (t) => {
  let requests = 0,
    attempts = 0;
  const base = await listen(
    t,
    createServer((req, res) => {
      requests++;
      res.end();
    }),
  );
  const failed = await dispatchCall({
    url: base,
    start: async () => {
      attempts++;
      return false;
    },
  });
  assert.equal(failed.state, "FAILED");
  assert.equal(attempts, 3);
  assert.equal(requests, 0);
  const succeeded = await dispatchCall({ url: base, start: async (attempt) => attempt > 1 });
  assert.equal(succeeded.state, "SUCCEEDED");
  assert.equal(requests, 1);
});
test("manual execute initial PENDING snapshot is distinct from terminal result", async (t) => {
  const base = await listen(
    t,
    createServer((req, res) => res.end()),
  );
  const queued = queueCall({ url: base });
  assert.equal(queued.initial.state, "PENDING");
  assert.equal((await queued.completion).state, "SUCCEEDED");
  assert.equal(queued.initial.state, "PENDING");
});
test("adapter retrieves CRM and preserves states, duties, parameters without assessment claims", async (t) => {
  const { adapter, triggerToken } = await setup(t);
  const response = await fetch(`${adapter}/trigger`, {
    method: "POST",
    headers: { authorization: `Bearer ${triggerToken}` },
    signal: AbortSignal.timeout(5000),
  });
  assert.equal(response.status, 200);
  const result = await response.json();
  assert.equal(result.assessed, false);
  assert.deepEqual(
    result.controls.map((r) => r.declared_state),
    ["implemented", "partial", "unknown"],
  );
  assert.equal(result.controls[0].effective_parameters[0].values[0], "30 days");
  assert.deepEqual(
    result.controls[0].customer_responsibilities,
    crmForPlan("managed").controls[0].required.responsibilities,
  );
  assert.ok(result.controls.every((r) => r.evidence.state === "not-assessed"));
});
test("adapter authentication, empty-body, method and path contract failures are explicit", async (t) => {
  const { adapter, triggerToken, crmToken, logs } = await setup(t);
  for (const authHeader of [undefined, `Bearer ${secret()}`, `Bearer ${crmToken}`]) {
    assert.equal((await dispatchCall({ url: `${adapter}/trigger`, authHeader })).http_status, 401);
  }
  const headers = { authorization: `Bearer ${triggerToken}` };
  assert.equal((await fetch(`${adapter}/trigger`, { headers })).status, 405);
  assert.equal(
    (await fetch(`${adapter}/trigger`, { method: "POST", headers, body: "{}" })).status,
    400,
  );
  assert.equal(
    (await fetch(`${adapter}/trigger`, { method: "POST", headers, body: "x".repeat(1025) })).status,
    413,
  );
  assert.equal(
    (await dispatchCall({ url: `${adapter}/wrong`, authHeader: headers.authorization }))
      .http_status,
    404,
  );
  assert.ok(logs.every((line) => !line.includes(triggerToken) && !line.includes(crmToken)));
});
test("configured tenant is used rather than caller-supplied tenant and unknown instance fails closed", async (t) => {
  const known = await setup(t, { instance: "demo-instance" });
  const response = await fetch(`${known.adapter}/trigger`, {
    method: "POST",
    headers: { authorization: `Bearer ${known.triggerToken}`, "x-crm-tenant": "attacker" },
  });
  assert.equal(response.status, 200);
  assert.equal((await response.json()).assessed, false);
  const missing = await setup(t, { instance: "unknown-instance" });
  assert.equal(
    (
      await dispatchCall({
        url: `${missing.adapter}/trigger`,
        authHeader: `Bearer ${missing.triggerToken}`,
      })
    ).http_status,
    502,
  );
});
test("duplicate read-only deliveries return stable context and do not mutate control status", async (t) => {
  const { adapter, triggerToken } = await setup(t);
  const before = JSON.stringify(createContext().crm("managed"));
  const results = [];
  for (let i = 0; i < 3; i++)
    results.push(
      await (
        await fetch(`${adapter}/trigger`, {
          method: "POST",
          headers: { authorization: `Bearer ${triggerToken}` },
        })
      ).json(),
    );
  assert.equal(new Set(results.map((r) => r.projection_sha256)).size, 1);
  assert.equal(JSON.stringify(createContext().crm("managed")), before);
});
test("upstream status, malformed JSON, schema, integrity and redirect faults fail closed", async (t) => {
  for (const fault of ["401", "404", "500", "malformed", "schema", "digest", "redirect"]) {
    const crmToken = secret(),
      triggerToken = secret();
    const base = await listen(
      t,
      createServer((req, res) => {
        res.setHeader("content-type", "application/json");
        if (fault === "redirect") {
          res.writeHead(302, { location: "https://example.org/" });
          return res.end();
        }
        if (/^\d+$/.test(fault)) {
          res.statusCode = Number(fault);
          return res.end("{}");
        }
        if (fault === "malformed") return res.end("{");
        if (req.url === "/v2/catalog") return res.end(JSON.stringify(createContext().catalog()));
        if (req.url.startsWith("/api/crm/")) {
          const crm = crmForPlan("managed");
          if (fault === "schema") crm.synthetic = false;
          return res.end(JSON.stringify(crm));
        }
        return res.end(JSON.stringify({ altered: true }));
      }),
    );
    const adapter = await listen(
      t,
      createTriggerAdapter({ crmBase: base, crmToken, triggerToken, audit: () => {} }),
    );
    const result = await dispatchCall({
      url: `${adapter}/trigger`,
      authHeader: `Bearer ${triggerToken}`,
    });
    assert.equal(result.http_status, 502, fault);
    assert.equal(result.state, "FAILED");
  }
});
test("slow and unavailable targets produce transport/adapter failure with bounded waits", async (t) => {
  const crmToken = secret(),
    triggerToken = secret();
  const slow = await listen(
    t,
    createServer((req, res) => {
      /* Deliberately never responds: timeout fault fixture. */
    }),
  );
  const adapter = await listen(
    t,
    createTriggerAdapter({ crmBase: slow, crmToken, triggerToken, timeoutMs: 30, audit: () => {} }),
  );
  assert.equal(
    (await dispatchCall({ url: `${adapter}/trigger`, authHeader: `Bearer ${triggerToken}` }))
      .http_status,
    502,
  );
  assert.equal((await dispatchCall({ url: slow, timeoutMs: 20 })).state, "FAILED");
  const closed = createServer();
  await new Promise((resolve) => closed.listen(0, "127.0.0.1", resolve));
  const port = closed.address().port;
  await new Promise((resolve) => closed.close(resolve));
  assert.equal((await dispatchCall({ url: `http://127.0.0.1:${port}` })).state, "FAILED");
});
test("adapter rejects remote targets, equal tokens and unapproved tenant configuration", () => {
  const common = { crmToken: secret(), triggerToken: secret(), crmBase: "http://127.0.0.1:8787" };
  assert.throws(
    () => createTriggerAdapter({ ...common, crmBase: "https://example.org/" }),
    /loopback/,
  );
  assert.throws(() => createTriggerAdapter({ ...common, tenant: "other" }), /tenant/);
  assert.throws(
    () => createTriggerAdapter({ ...common, triggerToken: common.crmToken }),
    /separate/,
  );
});
