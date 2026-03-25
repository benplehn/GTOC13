"""
Admissible upper bounds on the score reachable from a node.

V0: crude but NEVER underestimates.
Later versions tighten this without breaking admissibility.

INVARIANT: score_upper_bound(node) >= true_optimal_score_from(node)
This must be maintained by all functions here. Tightening = good.
Loosening = silent correctness bug. Never loosen without proof.
"""

"""
V0 upper bound: exact so far + maximum possible remaining contribution.

Components:
  1. Grand tour bonus (if still achievable in time).
  2. Sum of best possible score from each unvisited planet.
  3. Optimistic harvesting: every remaining body scores w_body * 1.0 * 1.0
     (S=1, V_inf factor=1 — the true maximum).
"""
function score_upper_bound_v0(node::BackboneNode, bodies::Vector{Body})
    ub = node.score_state.backbone_score + node.score_state.harvest_score

    t_remaining = node.resources.t_horizon - node.current_state.t
    t_remaining <= 0 && return ub

    # Backbone: unvisited planets
    for body in bodies
        body.class == PLANET || continue
        body.id ∈ node.resources.planets_visited && continue
        ub += body.w_body   # TODO: proper flyby score from statement
    end

    # Grand tour bonus
    n_small_visited = count(id -> is_massless(id) && id != ID_YANDI, node.resources.bodies_harvested)

    # Harvesting: every unscored body at best S=1, V=1
    n_small_reachable = 0
    for body in bodies
        body.class ∈ (ASTEROID, COMET) || continue
        body.id ∈ node.resources.bodies_harvested && continue
        # Only reachable if first perihelion has been done (or will be done)
        # Conservative: assume first perihelion will happen
        # TODO: tighten with reachability window check
        ub += body.w_body
        body.id != ID_YANDI && (n_small_reachable += 1)
    end

    gt_mult = grand_tour_bonus_ub(node.resources.planets_visited,
                                  n_small_visited,
                                  n_small_reachable)
    return gt_mult * ub
end

"""
Prune a node if its upper bound cannot beat the incumbent.
"""
function should_prune(node::BackboneNode, incumbent::Float64)
    return node.score_ub < incumbent
end
