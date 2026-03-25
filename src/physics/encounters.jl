"""
Encounter detection: find time windows where the spacecraft can reach a body
within the required V_inf budget.
"""

"""
Check if a massless encounter is geometrically feasible:
spacecraft state s, body state b_state at the same time, V_inf budget.
"""
function massless_encounter_feasible(s::CartesianState, b_r::SVector{3,Float64},
                                      b_v::SVector{3,Float64}, v_inf_max::Float64)
    Δv = s.v - b_v
    return norm(Δv) ≤ v_inf_max && norm(s.r - b_r) < 1e-3   # positional match
end

"""
Scan a time window [t0, t1] for candidate encounter epochs with a body.
Returns a list of (time, v_inf_approx) pairs.
Stub: full implementation uses a grid + refinement.
"""
function find_encounter_candidates(s0::CartesianState, body::Body,
                                    t0::Float64, t1::Float64,
                                    μ::Float64, v_inf_max::Float64;
                                    dt_grid::Float64=1.0)
    # TODO: grid search then Newton refine
    return Tuple{Float64,Float64}[]
end
