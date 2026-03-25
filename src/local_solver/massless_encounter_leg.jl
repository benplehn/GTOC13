"""
Massless encounter leg.

The spacecraft must match position AND V_inf direction/magnitude with
the small body at encounter time.
"""

function solve_massless_encounter_leg(dep::CartesianState, arr_time::Float64,
                                       body::Body, μ::Float64, v_inf_max::Float64)
    # TODO: Lambert arc or sail arc to rendezvous
    return INFEASIBLE_LEG
end
