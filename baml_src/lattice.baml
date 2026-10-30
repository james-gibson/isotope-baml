// SPDX-License-Identifier: AGPL-3.0-only
// 42i as a pure function: no model, no provider, no network.
// Port of the isotope package's weights and rung thresholds.

enum DeviationKind {
  CALLED_DURING_DEGRADED
  CALLED_DURING_UNHEALTHY
  CALLED_DURING_OUTAGE
  CALLED_DURING_REGRESSION
}

class Rung {
  rung int
  name string
  max_distance int
}

class Position {
  distance int
  rung int
  name string
  magnitude float
}

// isotope.DefaultWeights, keyed by the family a deviation maps to.
function Weight(kind: DeviationKind) -> int {
  match (kind) {
    DeviationKind.CALLED_DURING_DEGRADED => 20
    DeviationKind.CALLED_DURING_UNHEALTHY => 20
    DeviationKind.CALLED_DURING_OUTAGE => 20
    DeviationKind.CALLED_DURING_REGRESSION => 20
  }
}

function Thresholds() -> Rung[] {
  [
    Rung { rung: 0, name: "Absolute Zero", max_distance: 0 },
    Rung { rung: 1, name: "Read-Only", max_distance: 20 },
    Rung { rung: 2, name: "Harness Tools", max_distance: 60 },
    Rung { rung: 3, name: "Mock Secrets", max_distance: 100 },
    Rung { rung: 4, name: "Higher Authority", max_distance: 140 },
    Rung { rung: 5, name: "Delegation", max_distance: 180 },
    Rung { rung: 6, name: "Certification", max_distance: 220 }
  ]
}

// First-fit low-to-high, exactly as RungForDistance does.
function RungFor(distance: int) -> Rung {
  let ts = Thresholds();
  if (distance <= ts[0].max_distance) { ts[0] }
  else if (distance <= ts[1].max_distance) { ts[1] }
  else if (distance <= ts[2].max_distance) { ts[2] }
  else if (distance <= ts[3].max_distance) { ts[3] }
  else if (distance <= ts[4].max_distance) { ts[4] }
  else if (distance <= ts[5].max_distance) { ts[5] }
  else if (distance <= ts[6].max_distance) { ts[6] }
  else { ts[0] }
}

// Typed input: an integration fills the kinds it saw; everything else is null.
class Deviations {
  called_during_degraded int?
  called_during_unhealthy int?
  called_during_outage int?
  called_during_regression int?
}

function Count(v: int?) -> int {
  v ?? 0
}

function KindAt(i: int) -> DeviationKind {
  match (i) {
    0 => DeviationKind.CALLED_DURING_DEGRADED
    1 => DeviationKind.CALLED_DURING_UNHEALTHY
    2 => DeviationKind.CALLED_DURING_OUTAGE
    _ => DeviationKind.CALLED_DURING_REGRESSION
  }
}

function Distance(d: Deviations) -> int {
  let counts = [
    Count(d.called_during_degraded),
    Count(d.called_during_unhealthy),
    Count(d.called_during_outage),
    Count(d.called_during_regression)
  ];
  let total = 0;
  for (let i = 0; i < 4; i += 1) {
    total = total + counts[i] * Weight(KindAt(i));
  }
  total
}

function PositionOf(d: Deviations) -> Position {
  let dist = Distance(d);
  let r = RungFor(dist);
  Position { distance: dist, rung: r.rung, name: r.name, magnitude: 42.0 }
}
