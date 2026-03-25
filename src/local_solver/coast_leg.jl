"""
Ballistic (coast) leg: no thrust, pure Keplerian propagation.
Used when sail is furled (α = 90°).
"""

"""
Solve a coast leg by propagating departure state to arrival time.
Arrival constraint: position must match body position within tolerance.
"""
function solve_coast_leg(dep::CartesianState, arr_time::Float64,
                          body_r::SVector{3,Float64}, μ::Float64;
                          pos_tol::Float64=1e-4)
    arr_state = propagate_state(dep, arr_time - dep.t, μ)
    Δr = norm(arr_state.r - body_r)
    if Δr < pos_tol
        leg = Leg(LEG_COAST, dep.t, arr_time, dep, arr_state,
                  SailAttitude[], true, Δr)
        return LegSolution(leg, FEASIBLE, 0.0, Δr, "")
    else
        return LegSolution(nothing, INFEASIBLE, Inf, Δr,
                           "position mismatch: Δr=$(Δr) AU")
    end
end
