import { test } from "node:test";
import assert from "node:assert/strict";
import { randomBytes } from "node:crypto";
import { createApi } from "../server.mjs";

test("local mock broker provisions a synthetic instance and creates a synthetic account", async (t) => {
  const crmToken = randomBytes(32).toString("hex");
  const brokerToken = randomBytes(32).toString("hex");
  const logs = [];
  const server = createApi({ token: crmToken, brokerToken, audit: (line) => logs.push(line) });
  await new Promise((resolve) => server.listen(0, "127.0.0.1", resolve));
  t.after(() => new Promise((resolve) => server.close(resolve)));
  const base = `http://127.0.0.1:${server.address().port}`;
  const request = (path, options = {}) =>
    fetch(base + path, {
      ...options,
      headers: { authorization: `Bearer ${brokerToken}`, ...options.headers },
      signal: AbortSignal.timeout(5000),
    });
  assert.equal((await fetch(base + "/v2/service_instances/demo-broker-instance")).status, 401);
  const provision = () =>
    request("/v2/service_instances/demo-broker-instance", {
      method: "PUT",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ service_id: "managed-hosting", plan_id: "managed" }),
    });
  assert.equal((await provision()).status, 201);
  assert.equal((await provision()).status, 200);
  assert.equal(
    (await request("/v2/service_instances/demo-broker-instance/last_operation")).status,
    200,
  );
  const accountResponse = await request(
    "/api/mock/service-instances/demo-broker-instance/accounts",
    {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ display_label: "demo-operator" }),
    },
  );
  assert.equal(accountResponse.status, 201);
  const account = await accountResponse.json();
  assert.match(account.id, /^acct-[0-9a-f-]+$/);
  assert.equal(account.display_label, "demo-operator");
  assert.equal(
    (await request(`/api/mock/service-instances/demo-broker-instance/accounts/${account.id}`))
      .status,
    200,
  );
  const binding = () =>
    request("/v2/service_instances/demo-broker-instance/service_bindings/demo-binding", {
      method: "PUT",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ account_id: account.id }),
    });
  const bindingResponse = await binding();
  assert.equal(bindingResponse.status, 201);
  assert.deepEqual(await bindingResponse.json(), {
    credentials: { synthetic_account_ref: account.id, synthetic: true },
  });
  assert.equal((await binding()).status, 200);
  assert.equal(
    (
      await request("/v2/service_instances/other-instance", {
        method: "PUT",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({ service_id: "managed-hosting", plan_id: "managed" }),
      })
    ).status,
    201,
  );
  assert.equal(
    (
      await request("/v2/service_instances/other-instance/service_bindings/other-binding", {
        method: "PUT",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({ account_id: account.id }),
      })
    ).status,
    409,
  );
  assert.equal(
    (
      await request(
        `/api/mock/service-instances/demo-broker-instance/accounts/${account.id}/disable`,
        { method: "POST" },
      )
    ).status,
    200,
  );
  assert.equal((await binding()).status, 409);
  assert.equal(
    (
      await request("/v2/service_instances/demo-broker-instance/service_bindings/demo-binding", {
        method: "DELETE",
      })
    ).status,
    200,
  );
  assert.equal(
    (await request("/v2/service_instances/demo-broker-instance", { method: "DELETE" })).status,
    200,
  );
  assert.equal(
    (await request("/v2/service_instances/demo-broker-instance/last_operation")).status,
    404,
  );
  assert.equal(
    (
      await request("/api/mock/service-instances/unknown/accounts", {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({ display_label: "demo-operator" }),
      })
    ).status,
    404,
  );
  assert.equal(
    logs.some((line) => line.includes(brokerToken) || line.includes("demo-operator")),
    false,
  );
});

test("mock broker rejects bad credentials, invalid input and shared CRM credential", async (t) => {
  const crmToken = randomBytes(32).toString("hex");
  const brokerToken = randomBytes(32).toString("hex");
  const server = createApi({ token: crmToken, brokerToken, audit: () => {} });
  await new Promise((resolve) => server.listen(0, "127.0.0.1", resolve));
  t.after(() => new Promise((resolve) => server.close(resolve)));
  const base = `http://127.0.0.1:${server.address().port}`;
  const request = (path, options = {}) =>
    fetch(base + path, {
      ...options,
      headers: { authorization: `Bearer ${brokerToken}`, ...options.headers },
      signal: AbortSignal.timeout(5000),
    });
  assert.throws(() => createApi({ token: crmToken, brokerToken: crmToken }), /differ/);
  assert.equal(
    (
      await fetch(base + "/v2/service_instances/test", {
        headers: { authorization: `Bearer ${crmToken}` },
      })
    ).status,
    401,
  );
  assert.equal(
    (
      await request("/v2/service_instances/test", {
        method: "PUT",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({ service_id: "managed-hosting", plan_id: "unknown" }),
      })
    ).status,
    400,
  );
  assert.equal(
    (
      await request("/v2/service_instances/test", {
        method: "PUT",
        headers: { "content-type": "application/json" },
        body: "not-json",
      })
    ).status,
    400,
  );
  assert.equal((await request("/v2/service_instances/another", { method: "PUT" })).status, 400);
  assert.equal(
    (
      await request("/v2/service_instances/test/service_bindings/binding", {
        method: "PUT",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({ account_id: "acct-00000000-0000-4000-8000-000000000000" }),
      })
    ).status,
    404,
  );
});
