"""
Sail leg V0: piecewise-constant attitude parameterization.

The sail attitude (α, δ) is held constant over each segment.
Propagation by numerical integration of sail equations of motion.

This is the simplest sail model. Will be replaced by a proper SCP/lossless
formulation once the backbone search confirms the voile is a critical lever.
"""

function solve_sail_leg_v0(dep::CartesianState, arr_time::Float64,
                             arr_r::SVector{3,Float64}, β::Float64, μ::Float64;
                             n_segments::Int=5)
    # TODO: piecewise constant NLP
    return INFEASIBLE_LEG
end
