import { randomUUID } from "node:crypto";

const identifier = /^[a-z][a-z0-9-]{0,63}$/;
const label = /^[a-z][a-z0-9-]{1,31}$/;

function error(status, code, description) {
  return { status, body: { error: code, description } };
}

function validObject(value) {
  return value && typeof value === "object" && !Array.isArray(value);
}

export function createMockBroker({ context, audit = console.log } = {}) {
  if (!context) throw new Error("Mock broker requires a CRM context");
  const instances = new Map();
  const event = (name, status) =>
    audit(
      JSON.stringify({
        timestamp: new Date().toISOString(),
        agent: "AI-assisted CRM prototype/0.1.0",
        event: name,
        status,
        synthetic: true,
      }),
    );
  const catalog = () => context.catalog();
  const provision = (id, input) => {
    if (!identifier.test(id))
      return error(400, "INVALID_INSTANCE_ID", "Use a documented instance ID");
    if (
      !validObject(input) ||
      Object.keys(input).some((key) => !["service_id", "plan_id"].includes(key))
    )
      return error(400, "INVALID_REQUEST", "Only service_id and plan_id are accepted");
    if (!identifier.test(input.service_id || "") || !identifier.test(input.plan_id || ""))
      return error(400, "INVALID_REQUEST", "service_id and plan_id are required identifiers");
    const service = catalog().services.find((entry) => entry.id === input.service_id);
    const plan = service?.plans.find((entry) => entry.id === input.plan_id);
    if (!plan) return error(400, "INVALID_PLAN", "The synthetic service or plan is unavailable");
    const existing = instances.get(id);
    if (existing) {
      if (existing.service_id !== input.service_id || existing.plan_id !== input.plan_id)
        return error(409, "CONFLICT", "Instance ID is already assigned to another synthetic plan");
      event("mock_broker_provision", 200);
      return { status: 200, body: { dashboard_url: null } };
    }
    instances.set(id, {
      id,
      service_id: input.service_id,
      plan_id: input.plan_id,
      accounts: new Map(),
      bindings: new Map(),
    });
    event("mock_broker_provision", 201);
    return { status: 201, body: { dashboard_url: null } };
  };
  const operation = (id) => {
    if (!instances.has(id)) return error(404, "NOT_FOUND", "Synthetic instance not found");
    event("mock_broker_last_operation", 200);
    return {
      status: 200,
      body: { state: "succeeded", description: "Synthetic in-memory operation" },
    };
  };
  const deprovision = (id) => {
    if (!instances.delete(id)) return error(404, "NOT_FOUND", "Synthetic instance not found");
    event("mock_broker_deprovision", 200);
    return { status: 200, body: {} };
  };
  const createAccount = (id, input) => {
    const instance = instances.get(id);
    if (!instance) return error(404, "NOT_FOUND", "Synthetic instance not found");
    if (!validObject(input) || Object.keys(input).some((key) => key !== "display_label"))
      return error(400, "INVALID_REQUEST", "Only display_label is accepted");
    if (!label.test(input.display_label || ""))
      return error(400, "INVALID_LABEL", "display_label must be a non-sensitive demo label");
    const account = {
      id: `acct-${randomUUID()}`,
      display_label: input.display_label,
      status: "active",
      synthetic: true,
    };
    instance.accounts.set(account.id, account);
    event("mock_account_create", 201);
    return { status: 201, body: structuredClone(account) };
  };
  const getAccount = (instanceId, accountId) => {
    const account = instances.get(instanceId)?.accounts.get(accountId);
    if (!account) return error(404, "NOT_FOUND", "Synthetic account not found");
    event("mock_account_read", 200);
    return { status: 200, body: structuredClone(account) };
  };
  const disableAccount = (instanceId, accountId) => {
    const account = instances.get(instanceId)?.accounts.get(accountId);
    if (!account) return error(404, "NOT_FOUND", "Synthetic account not found");
    if (account.status === "disabled") {
      event("mock_account_disable", 200);
      return { status: 200, body: structuredClone(account) };
    }
    account.status = "disabled";
    for (const binding of instances.get(instanceId).bindings.values()) {
      if (binding.account_id === accountId) binding.status = "disabled";
    }
    event("mock_account_disable", 200);
    return { status: 200, body: structuredClone(account) };
  };
  const bind = (instanceId, bindingId, input) => {
    const instance = instances.get(instanceId);
    if (!instance) return error(404, "NOT_FOUND", "Synthetic instance not found");
    if (!identifier.test(bindingId))
      return error(400, "INVALID_BINDING_ID", "Use a documented binding ID");
    if (!validObject(input) || Object.keys(input).some((key) => key !== "account_id"))
      return error(400, "INVALID_REQUEST", "Only account_id is accepted");
    const account = instance.accounts.get(input.account_id);
    if (!account || account.status !== "active")
      return error(
        409,
        "ACCOUNT_UNAVAILABLE",
        "Use an active account owned by this synthetic instance",
      );
    const existing = instance.bindings.get(bindingId);
    if (existing) {
      if (existing.account_id !== input.account_id)
        return error(409, "CONFLICT", "Binding ID is assigned to another synthetic account");
      event("mock_broker_bind", 200);
      return { status: 200, body: structuredClone(existing.response) };
    }
    const response = {
      credentials: { synthetic_account_ref: account.id, synthetic: true },
    };
    instance.bindings.set(bindingId, {
      account_id: account.id,
      status: "active",
      response,
    });
    event("mock_broker_bind", 201);
    return { status: 201, body: structuredClone(response) };
  };
  const unbind = (instanceId, bindingId) => {
    const instance = instances.get(instanceId);
    if (!instance || !instance.bindings.delete(bindingId))
      return error(404, "NOT_FOUND", "Synthetic binding not found");
    event("mock_broker_unbind", 200);
    return { status: 200, body: {} };
  };
  return {
    catalog,
    provision,
    operation,
    deprovision,
    createAccount,
    getAccount,
    disableAccount,
    bind,
    unbind,
  };
}
