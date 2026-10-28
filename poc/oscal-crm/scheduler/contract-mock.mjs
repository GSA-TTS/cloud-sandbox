// Test model derived from upstream source, NOT the real OCF scheduler runtime.
export const schedulerReference = {
  repository: "GSA-TTS/ocf-scheduler",
  revision: "8f070f0aed8c622ec22b82a053a11af37d1de4dc",
  sources: [
    "http/run_service.go",
    "http/run_service_test.go",
    "core/calls.go",
    "http/routes/execute_test.go",
  ],
};
export function loopbackUrl(value) {
  const url = new URL(value);
  if (
    url.protocol !== "http:" ||
    url.hostname !== "127.0.0.1" ||
    !url.port ||
    url.username ||
    url.password ||
    url.search ||
    url.hash
  ) {
    throw new Error(
      "Test targets must be explicit loopback HTTP URLs without credentials or queries",
    );
  }
  return url;
}
export async function dispatchCall({
  url,
  authHeader,
  start = async () => true,
  startAttempts = 3,
  timeoutMs = 500,
}) {
  loopbackUrl(url);
  if (
    !Number.isInteger(startAttempts) ||
    startAttempts < 1 ||
    startAttempts > 5 ||
    !Number.isInteger(timeoutMs) ||
    timeoutMs < 1 ||
    timeoutMs > 5000
  ) {
    throw new Error("Invalid bounded mock settings");
  }
  const execution = { state: "PENDING", message: "", mocked_scheduler: true, http_status: null };
  let started = false;
  for (let attempt = 1; attempt <= startAttempts; attempt++) {
    if (await start(attempt)) {
      started = true;
      break;
    }
  }
  if (!started)
    return { ...execution, state: "FAILED", message: "Start recording failed; request skipped" };
  execution.state = "RUNNING";
  try {
    const response = await fetch(url, {
      method: "POST",
      headers: authHeader ? { authorization: authHeader } : {},
      redirect: "manual",
      signal: AbortSignal.timeout(timeoutMs),
    });
    await response.body?.cancel();
    execution.http_status = response.status;
    execution.state = response.ok ? "SUCCEEDED" : "FAILED";
    execution.message = response.ok ? "POST success" : "Target rejected request";
  } catch {
    execution.state = "FAILED";
    execution.message = "Target transport failed";
  }
  return execution;
}
export function queueCall(call) {
  const initial = { state: "PENDING", message: "", mocked_scheduler: true };
  return { initial, completion: Promise.resolve().then(() => dispatchCall(call)) };
}
