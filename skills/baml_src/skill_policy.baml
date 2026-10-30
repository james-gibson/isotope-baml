// Field-level authorisation across a federated pair of skills.
//
// A federated query names fields from more than one subgraph. Which of those a
// caller may resolve is a policy decision, not a routing one: cheap fields come
// from a local index, expensive fields cost a remote authoritative call.

enum Tier {
  CHEAP
  EXPENSIVE
}

class FieldPolicy {
  cheap_fields string[]
  expensive_fields string[]
}

function TierOf(field: string, p: FieldPolicy) -> Tier {
  for (let i = 0; i < p.expensive_fields.length(); i += 1) {
    if (p.expensive_fields[i] == field) {
      return Tier.EXPENSIVE;
    }
  }
  Tier.CHEAP
}

// Cheap fields are always resolvable. Expensive fields need the caller inside
// policy, so a drift in boundary compliance costs money, not correctness.
function Authorise(field: string, d: Deviations, p: FieldPolicy) -> Decision {
  if (TierOf(field, p) == Tier.CHEAP) {
    return Decision { allow: true, reason: "cheap field from the local plane" };
  }
  Decide(d, Policy { refuse_above: 0 })
}

test "cheap field is always allowed" {
  let fp = FieldPolicy {
    cheap_fields: ["mentions", "documents"],
    expensive_fields: ["vulns", "versions"]
  };
  assert.is_true(Authorise("mentions", Deviations { called_during_degraded: 5 }, fp).allow)
}

test "expensive field is refused for a drifting caller" {
  let fp = FieldPolicy {
    cheap_fields: ["mentions", "documents"],
    expensive_fields: ["vulns", "versions"]
  };
  assert.equal(Authorise("vulns", Deviations { called_during_degraded: 1 }, fp).allow, false)
}

test "expensive field is allowed for a clean caller" {
  let fp = FieldPolicy {
    cheap_fields: ["mentions", "documents"],
    expensive_fields: ["vulns", "versions"]
  };
  assert.is_true(Authorise("vulns", Deviations {}, fp).allow)
}
