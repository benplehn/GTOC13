"""
Encounter detection: find time windows where the spacecraft can reach a body
within the required V_inf budget.
"""

"""
Check if a massless encounter is geometrically feasible:
spacecraft state s, body state b_state at the same time, V_inf budget.
"""
function same_position_at_flyby(spacecraft_r::SVector{3,Float64}, body_r::SVector{3,Float64};
                                pos_tol::Float64=FLYBY_POSITION_TOL_AU)
    require_distance_au(spacecraft_r; name="spacecraft flyby position")
    require_distance_au(body_r; name="body flyby position")
    return norm(spacecraft_r - body_r) ≤ pos_tol
end

function same_position_at_flyby(s::CartesianState, body_r::SVector{3,Float64};
                                pos_tol::Float64=FLYBY_POSITION_TOL_AU)
    return same_position_at_flyby(s.r, body_r; pos_tol=pos_tol)
end

function require_same_position_at_flyby(spacecraft_r::SVector{3,Float64}, body_r::SVector{3,Float64};
                                        pos_tol::Float64=FLYBY_POSITION_TOL_AU)
    same_position_at_flyby(spacecraft_r, body_r; pos_tol=pos_tol) && return true
    error("Flyby position mismatch exceeds tolerance $(pos_tol) AU")
end

function require_same_position_at_flyby(s::CartesianState, body_r::SVector{3,Float64};
                                        pos_tol::Float64=FLYBY_POSITION_TOL_AU)
    return require_same_position_at_flyby(s.r, body_r; pos_tol=pos_tol)
end

function massless_vinf_continuous(v_inf_in::SVector{3,Float64}, v_inf_out::SVector{3,Float64};
                                  tol::Float64=1e-12)
    require_velocity_auday(v_inf_in; name="incoming massless V∞")
    require_velocity_auday(v_inf_out; name="outgoing massless V∞")
    return norm(v_inf_out - v_inf_in) ≤ tol
end

function massless_vinf_continuous(v_sc_in::SVector{3,Float64},
                                  v_sc_out::SVector{3,Float64},
                                  body_v::SVector{3,Float64};
                                  tol::Float64=1e-12)
    return massless_vinf_continuous(v_sc_in - body_v, v_sc_out - body_v; tol=tol)
end

function require_massless_vinf_continuity(v_inf_in::SVector{3,Float64}, v_inf_out::SVector{3,Float64};
                                          tol::Float64=1e-12)
    massless_vinf_continuous(v_inf_in, v_inf_out; tol=tol) && return true
    error("Massless encounter requires full V∞ continuity")
end

function require_massless_vinf_continuity(v_sc_in::SVector{3,Float64},
                                          v_sc_out::SVector{3,Float64},
                                          body_v::SVector{3,Float64};
                                          tol::Float64=1e-12)
    return require_massless_vinf_continuity(v_sc_in - body_v, v_sc_out - body_v; tol=tol)
end

function massless_encounter_feasible(s::CartesianState, b_r::SVector{3,Float64},
                                      b_v::SVector{3,Float64}, v_inf_max::Float64)
    Δv = s.v - b_v
    return norm(Δv) ≤ v_inf_max && same_position_at_flyby(s, b_r)
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
