"""
Convex relaxation of sail dynamics for bound computation.

Based on the lossless control-convex formulation (Oguri & Lantoine 2025).
Phase 9+ concern. Stub only.
"""

function sail_convex_ub(dep::CartesianState, arr_time::Float64,
                         arr_r::SVector{3,Float64}, β::Float64, μ::Float64)
    # TODO: convex/lossless reformulation
    return Inf
end
