"""
Benders-like cuts from subproblem failures.

When the local solver fails on a (backbone, timing) pair,
it can generate a cut that invalidates similar combinations in the master.

Cut types implemented here:
  1. Score ceiling cut: "with this resource state, max achievable score ≤ X"
  2. Feasibility cut: "this resource+timing combination is infeasible"
  3. Perihelion timing cut: "deep perihelion at t > T_critical blocks body Y"
"""

"""
Generate a score ceiling cut from a solved subproblem.
"""
function generate_score_ceiling_cut(node::BackboneNode,
                                     max_score::Float64)
    return ScoreThresholdCut(max_score)
end

"""
Generate a feasibility cut when deep perihelion is consumed too late
to allow grand-tour completion.
"""
function generate_perihelion_timing_cut(node::BackboneNode,
                                         planet_id::Int,
                                         t_critical::Float64)
    node.current_state.t > t_critical || return nothing
    return ResourceConflictCut(planet_id,
        "deep perihelion consumed after t=$(t_critical), cannot reach planet $(planet_id)")
end
