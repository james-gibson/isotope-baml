// SPDX-License-Identifier: AGPL-3.0-only
// The gate decision, as a pure function. Same inputs, same answer, no model.

class Policy {
  // Refuse when a caller's distance exceeds this. 0 means "refuse on any
  // deviation"; a large number means "record only".
  refuse_above int
}

class Decision {
  allow bool
  reason string
}

function Decide(d: Deviations, p: Policy) -> Decision {
  if (Distance(d) > p.refuse_above) {
    Decision { allow: false, reason: "distance exceeds policy" }
  } else {
    Decision { allow: true, reason: "within policy" }
  }
}

test "clean caller is allowed" {
  assert.is_true(Decide(Deviations {}, Policy { refuse_above: 20 }).allow)
}

test "one deviation inside policy is allowed" {
  assert.is_true(Decide(Deviations { called_during_degraded: 1 }, Policy { refuse_above: 20 }).allow)
}

test "two deviations exceed policy" {
  assert.equal(Decide(Deviations { called_during_degraded: 2 }, Policy { refuse_above: 20 }).allow, false)
}

test "distance of two degraded calls is 40" {
  assert.equal(Distance(Deviations { called_during_degraded: 2 }), 40)
}

test "rung for 60 is Harness Tools" {
  assert.equal(PositionOf(Deviations { called_during_degraded: 3 }).name, "Harness Tools")
}
