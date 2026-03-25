"""
Massive flyby leg: Lambert arc + patched-conic flyby.

Given departure state at t_dep and planet state at t_arr,
solve Lambert problem for transfer, then apply patched-conic at arrival.
"""

function solve_massive_flyby_leg(dep::CartesianState, arr_time::Float64,
                                   planet::Body, μ::Float64)
    # TODO: Lambert solver + patched conic
    # For now, return infeasible stub
    return INFEASIBLE_LEG
end
