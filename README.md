# isotope-baml

The 42i lattice as pure BAML functions: weights, rung thresholds, distance,
position, and a gate policy. No model, no provider, no network — so it can be
checked and tested offline, and pinned by any number of skills.

This is a port of the Go `isotope` package's lattice arithmetic. The Go package
remains the reference implementation; agreement with it is the test that this
port means the same thing.

## What it provides

| Symbol | Meaning |
| --- | --- |
| `Weight(DeviationKind)` | 42i distance added by one deviation |
| `Thresholds()` | the seven rungs and their maximum tolerated distance |
| `RungFor(distance)` | first-fit low-to-high, as the reference does |
| `Distance(Deviations)` | accumulated distance from observed deviations |
| `PositionOf(Deviations)` | distance, rung, rung name |
| `Decide(Deviations, Policy)` | allow/refuse against a policy threshold |
| `skills/` | two plane universes composed as a federated graph |

`Deviations` is a typed class with optional counts, not a `map<string, int>`:
BAML maps panic on a missing key, and an optional field reads better in a
generated schema.

## Use it

```sh
baml check --agent-skill-check off
baml test  --agent-skill-check off        # five fixtures, no provider
baml pack PositionOf --agent-skill-check off
./forty-two-i --json-args '{"d":{"called_during_degraded":2}}'
# {"distance":40,"rung":2,"name":"Harness Tools","magnitude":42.0}
```

`baml pack` produces a ~34 MB standalone binary. Treat it as build output: keep
it out of git and regenerate it. It is the fast path (~0.10s per call) for a
process that cannot carry the toolchain; `baml run -e` is the slow path
(~0.60s) that needs no build step. Both must return the same canonical position
— that equivalence is what makes one a rotation of the other.

## Vendoring, until BAML has packages

`[dependencies]` in `baml.toml` is not supported yet ("package imports are
pending a design pass"), so a consumer copies these files and records what it
copied:

```sh
./scripts/vendor.sh /path/to/consumer    # copies baml_src/*.baml, writes LATTICE_VENDORED
./scripts/verify.sh /path/to/consumer    # non-zero if a copy drifted
```

`LATTICE_VENDORED` pins the source commit and a sha256 per file. A hash proves a
copy did not change. It cannot prove the copy still *means* the same thing —
that needs the behavioural check in the consumer (this lattice vs the Go
reference on the same inputs). Run both; a faithful copy of a wrong port hashes
correctly.

When BAML gains package imports, the pins collapse into one dependency entry and
the copies disappear.

## Composing a cheap check with an expensive one

The reason this is a standalone artifact rather than a file inside one project:
several skills want the same policy arithmetic over different cost tiers.

A dependency-scan skill is the worked example. `pkg.go.dev` publishes a free
REST API that includes `/v1/vulns/{path}` — module vulnerabilities — plus
package, module, version and symbol lookups. That is cheap enough to call for
every dependency. A deeper scan (a paid SCA API, or an authenticated scanner) is
not.

So the skill runs the cheap check first, and only spends on the expensive one
when the cheap result says something is there:

```
for each dependency:
    cheap = GET /v1/vulns/{path}          # free, always
    if cheap reports a vulnerability:
        expensive = deep_scan(path)       # only here
        Decide(deviations, policy)        # the same policy arithmetic
```

The lattice's contribution is not the scoring — it is that the *decision to
spend* is a pure function of observed evidence, recorded with a digest of the
evidence it saw. That is the same shape as the rotation gate: a request may
choose a route, but only a proven decision may authorise a cost.

Three rules carry over unchanged:

1. **A tier is routing, not policy.** Cheap and expensive paths must return
   equivalent answers for the same input, or the cheap one is a different check.
2. **A switch costs a proof.** Promoting a finding from the cheap tier to the
   expensive one should carry the evidence that caused it, with a digest.
3. **Absence must be visible.** "No vulnerability" and "could not check" are
   different results; a failed lookup must not read as clean.

## What this is not

- **Not a trust score.** A rung is a certification ceiling on tolerated drift;
  higher rungs tolerate *more* distance. A caller sitting at rung 0 is the
  best-behaved, not the worst. Compare on distance.
- **Not a safety certificate.** Distance measures boundary compliance — whether
  a caller kept acting on a surface already declared non-nominal. It does not
  predict whether an operation will fail or whether a machine is safe.
- **Not a model judgement.** Nothing here calls an LLM. A model that emits its
  own distance is grading itself.

## Licence

AGPL-3.0, matching the rest of the lab: `isotope`, `adhd`, `tuner`,
`smoke-alarm` and `lezz.go` are all AGPL-3.0, as is the job dispatcher this was
built against. Vendoring these sources carries the same licence, which is the
intended arrangement rather than a concession — the lattice is meant to be
shared and inspectable, and the licence is what keeps a derived decision
auditable.

Source files carry `SPDX-License-Identifier: AGPL-3.0-only`, so the licence
travels with a vendored copy even when the LICENSE file is left behind.

## Skills

`skills/` holds two reference *plane universes* that vendor this lattice and
compose as a federated graph: a cheap local search plane and an authoritative
pkg.go.dev plane. See `skills/README.md`.
