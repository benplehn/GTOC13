"""
Optimistic upper bound on harvesting score from current node.

Strategy:
  1. Enumerate all unscored small bodies.
  2. For each, compute best achievable score ignoring transfer feasibility.
  3. Sum, with S=1, V=1 (maximum possible per-encounter factors).

Later: tighten via angular coverage model (submodular relaxation).
"""

function optimistic_harvesting_score(node::BackboneNode, bodies::Vector{Body})
    first_peri_possible = true   # conservative: assume it will happen
    !node.resources.first_perihelion_done && !first_peri_possible && return 0.0

    sc = 0.0
    for body in bodies
        body.class ∈ (ASTEROID, COMET) || continue
        body.id ∈ node.resources.bodies_harvested && continue
        sc += body.w_body * seasonal_factor_upper_bound(
            SVector{3,Float64}[], 1)   # best possible single encounter
    end
    return sc
end
