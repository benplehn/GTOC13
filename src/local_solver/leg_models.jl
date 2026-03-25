"""
Leg model interface.

A leg model answers: given departure state and arrival constraint,
is the transfer feasible? What is its cost?

All leg models implement:
  solve_leg(model, dep_state, arr_constraint, ...) → LegSolution
"""

@enum LegFeasibility begin
    FEASIBLE
    DOUBTFUL    # local solver converged but residual is borderline
    INFEASIBLE
end

struct LegSolution
    leg         :: Union{Leg, Nothing}
    feasibility :: LegFeasibility
    cost        :: Float64   # e.g. |Δv| or ∫|a_sail| dt
    residual    :: Float64
    info        :: String
end

INFEASIBLE_LEG = LegSolution(nothing, INFEASIBLE, Inf, Inf, "")
