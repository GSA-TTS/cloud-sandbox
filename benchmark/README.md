# Managed Kubernetes Benchmark Harness

This harness validates benchmark metadata and normalized observations before a
result package is published. It does not provision clusters or execute
workloads.

## Validate The Fixtures

```sh
bash scripts/validate-kubernetes-benchmark.sh \
  benchmark/fixtures/protocol.yaml \
  benchmark/fixtures/toolchain.lock.yaml \
  benchmark/fixtures/observations.ndjson
```

The validator checks each input against the schemas in `benchmark/schemas/` and
then applies cross-file checks:

- observation providers, profile, workloads, repetitions, and seeds must be
  declared by the protocol;
- every observation must carry the SHA-256 digest of the exact protocol file;
- tool names must be unique; and
- every tool referenced by an observation must be present in the toolchain lock
  with the same version and checksum.

The command exits nonzero and reports all detected validation errors. Inputs
must contain synthetic, non-sensitive metadata only.

## Input Contract

`protocol.yaml` freezes the comparison profile and run matrix. Repetition
numbers are one-based and map positionally to the seeds array.

`toolchain.lock.yaml` pins each executable or image by exact version and
SHA-256 checksum. OCI images additionally require an immutable digest.

`observations.ndjson` contains one normalized observation per nonblank line.
Failed or excluded observations remain in the file and require an
`exclusion_reason`; valid observations must set it to `null`.

See `docs/kubernetes/benchmark-protocol.md` for the methodology, security gate,
workload definitions, and complete artifact layout.
