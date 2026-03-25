"""
Optimistic upper bound on remaining backbone score.

Relaxes: timing constraints, V_inf budget, exact perihelion conditions.
Keeps: resource logic (deep perihelion uniqueness, planet ordering).
"""

function optimistic_backbone_score(node::BackboneNode, bodies::Vector{Body})
    # V0: sum of all unvisited planet weights
    sc = 0.0
    for body in bodies
        body.class == PLANET || continue
        body.id ∈ node.resources.planets_visited && continue
        sc += body.w_body
    end
    return sc
end
