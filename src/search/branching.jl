"""
Branching logic: generate candidate children from a node.

V0 branches only on:
  - next perihelion (deep or standard)
  - next planet (massive flyby)
  - "wait/coast" macro-step

Small bodies (harvesting) are NOT branched here — handled separately.
"""

"""
Generate backbone branch candidates from `node`.
Returns a vector of EncounterCandidate, sorted by optimistic score (desc).
"""
function generate_branches(node::BackboneNode,
                             bodies::Vector{Body},
                             μ::Float64;
                             t_lookahead::Float64=365.0)
    candidates = EncounterCandidate[]

    t_now = node.current_state.t
    t_max = min(t_now + t_lookahead, node.resources.t_horizon)

    for body in bodies
        body.class == PLANET || continue
        body.id ∈ node.resources.planets_visited && continue

        # Estimate encounter window (stub: use full lookahead)
        cand = EncounterCandidate(
            body.id,
            EVT_MASSIVE_FLYBY,
            t_now, t_max,
            0.0, 0.0,   # TODO: fill v_inf_approx, Δv_approx
            0.0         # TODO: fill score_upper
        )
        push!(candidates, cand)
    end

    # Perihelion branch
    if !node.resources.deep_perihelion_used
        push!(candidates, EncounterCandidate(
            -1, EVT_PERIHELION,
            t_now, t_max,
            0.0, 0.0, 0.0
        ))
    end

    # Sort by optimistic score descending
    sort!(candidates, by=c -> -c.score_upper)
    return candidates
end
