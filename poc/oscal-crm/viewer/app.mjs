// All API-derived content uses textContent, never HTML interpolation.
let token = "";
let revision = 0;
let plans = [];
const element = (id) => document.getElementById(id);
function text(tag, value, parent) {
  const node = document.createElement(tag);
  node.textContent = value;
  parent.append(node);
  return node;
}
async function request(path) {
  if (!token) throw new Error("Connect with your local token first.");
  const response = await fetch(path, {
    headers: { authorization: `Bearer ${token}` },
    cache: "no-store",
    signal: AbortSignal.timeout(5000),
  });
  if (!response.ok) throw new Error(`API request rejected (${response.status}).`);
  return response.json();
}
async function load() {
  const current = ++revision;
  try {
    element("status").textContent = "Loading CRM…";
    const selected = plans[Number(element("plan").value)];
    if (!selected) throw new Error("No discovered plan selected.");
    const crm = await request(selected.href);
    const notes = await request("/api/notes/component-model");
    if (current !== revision) return;
    element("rows").replaceChildren();
    for (const row of crm.controls) await renderRow(row, current);
    if (current !== revision) return;
    element("notes").textContent = notes.markdown;
    element("status").textContent =
      `${crm.plan_id}: ${crm.controls.length} component-scoped rows. All evidence is not assessed.`;
  } catch (error) {
    if (current === revision) element("status").textContent = error.message;
  }
}
async function renderRow(row, current) {
  const component = await request(`/api/components/${row.component_uuid}`);
  if (current !== revision) return;
  const section = document.createElement("article");
  text("h2", `${row.control_id.toUpperCase()} — ${component.title}`, section);
  text(
    "p",
    `Statement: ${row.statement_id} · Declared: ${row.implemented.declared_state} · Evidence: ${row.implemented.evidence.state}`,
    section,
  );
  const columns = text("div", "", section);
  columns.className = "columns";
  const provider = text("section", "", columns);
  text("h3", "Provider implements", provider);
  text("p", row.implemented.narrative, provider);
  text(
    "p",
    `Roles: ${row.implemented.responsible_roles.join(", ")}; claim basis: ${row.implemented.claim_basis}`,
    provider,
  );
  const customer = text("section", "", columns);
  text("h3", "Customer must implement", customer);
  for (const responsibility of row.required.responsibilities)
    text("p", responsibility.description, customer);
  text("p", `Obligation: ${row.required.state}; inheritance: ${row.inheritance.state}`, customer);
  const details = text("details", "", section);
  text("summary", "Component, parameters and source references", details);
  text("p", component.description, details);
  text(
    "pre",
    JSON.stringify(
      {
        component_uuid: row.component_uuid,
        parameters: row.effective_parameters,
        source_refs: row.source_refs,
        document: component.source,
      },
      null,
      2,
    ),
    details,
  );
  element("rows").append(section);
}
element("connect").addEventListener("submit", async (event) => {
  event.preventDefault();
  token = element("token").value;
  element("token").value = "";
  element("comparison").replaceChildren();
  const current = ++revision;
  try {
    const catalog = await request("/v2/catalog");
    if (current !== revision) return;
    plans = catalog.services.flatMap((service) =>
      service.plans.map((plan) => ({
        offering: service.id,
        plan: plan.id,
        href: `/api/crm/offerings/${encodeURIComponent(service.id)}/plans/${encodeURIComponent(plan.id)}`,
      })),
    );
    element("plan").replaceChildren();
    plans.forEach((plan, index) => {
      const option = text("option", `${plan.offering} / ${plan.plan}`, element("plan"));
      option.value = String(index);
    });
    await load();
  } catch (error) {
    if (current === revision) element("status").textContent = error.message;
  }
});
element("disconnect").addEventListener("click", () => {
  token = "";
  plans = [];
  revision++;
  element("token").value = "";
  for (const id of ["rows", "notes", "comparison"]) element(id).replaceChildren();
  element("status").textContent = "Disconnected; token and displayed data cleared.";
});
element("plan").addEventListener("change", load);
element("compare").addEventListener("click", async () => {
  const current = revision;
  try {
    const selected = plans[Number(element("plan").value)];
    const pair = plans.filter((p) => p.offering === selected?.offering);
    if (pair.length < 2) throw new Error("This offering needs two plans for comparison.");
    const comparison = await request(
      `/api/crm/compare/${encodeURIComponent(pair[0].plan)}/${encodeURIComponent(pair[1].plan)}`,
    );
    if (current !== revision) return;
    element("comparison").replaceChildren();
    text(
      "h2",
      `${comparison.from_plan} → ${comparison.to_plan} declaration changes`,
      element("comparison"),
    );
    for (const change of comparison.changes)
      text(
        "p",
        `${(change.before || change.after).control_id.toUpperCase()}: ${change.changed_fields.join(", ")}`,
        element("comparison"),
      );
    text("p", comparison.interpretation, element("comparison"));
  } catch (error) {
    if (current === revision) element("status").textContent = error.message;
  }
});
