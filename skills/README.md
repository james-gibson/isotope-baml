# Skills as isotope planes

Two dynamic skills, each a plane universe, composed as a federated graph.

| Skill | Universe | Tier | Answers |
| --- | --- | --- | --- |
| `search/` | `lab:skill-search:2026` | cheap | where a module or symbol is mentioned, from a local index |
| `pkgsite/` | `lab:skill-pkgsite:2026` | expensive | module, version and vulnerability facts from the published pkg.go.dev API |

A plane is not a service. Each `plane.json` states what the skill *promises*
(`nominal`), which planes it presupposes, and which of its fields are cheap. The
42i distance is the departure from that nominal, so the same measurement applies
to a skill as to a caller.

## Federation, not chaining

Both subgraphs declare `Module`, keyed by `path`. The router joins on that key,
so one query spans both planes:

```graphql
query {
  module(path: "golang.org/x/pkgsite") {
    path
    mentions          # cheap: local index
    documents { uri } # cheap: local index
    vulns { id }      # expensive: authoritative, rate limited
  }
}
```

The join key is the whole composition. A skill that answers about a module
declares the module; it does not call the other skill. Chaining would make the
expensive call a prerequisite for the cheap answer; federation makes it a
sibling the query may or may not ask for.

`supergraph/composition.graphql` shows the merged shape. `*.graphql` files are
illustrative SDL: there is no router in this repository (no Node runtime here),
so nothing validates the composition yet. The policy below *is* tested.

## The tier is a policy, not an ordering

`baml_src/skill_policy.baml` decides which fields a caller may resolve:

- **cheap fields are always allowed** — they cost nothing and never leave the
  host;
- **expensive fields require the caller inside policy** — a caller accumulating
  distance loses the authoritative tier first.

```
cheap field, drifting caller     -> allowed   (local plane)
expensive field, drifting caller -> refused   (authoritative plane)
expensive field, clean caller    -> allowed
```

Three tests, 8 total with the vendored lattice, no provider and no network.

## What carries over from the lattice

The weights do not. A vulnerability severity is not a caller deviation; the 42i
weight table would be wrong for it. What carries over is the shape:

1. a spend decision that is a pure function of observed evidence;
2. recorded with a digest of the evidence it saw;
3. where absence is distinct from "could not check" — a failed authoritative
   lookup must not read as "no vulnerabilities".

## Licence

`isotope-baml` is AGPL-3.0. The vendored copies here are the same licence, and a
consumer that vendors them inherits it. If that is unwanted for a given
consumer, call the packed binary across a process boundary instead of copying
the source — but then the equivalence proof (`lattice_paths`) has to cross that
boundary too.
