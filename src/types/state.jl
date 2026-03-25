"""
Spacecraft state and leg representations.
All positions in AU, velocities in AU/day, time in Julian days.
"""

"""
Full 6-DOF spacecraft state at an instant.
"""
struct CartesianState
    t   :: Float64
    r   :: SVector{3, Float64}   # position [AU]
    v   :: SVector{3, Float64}   # velocity [AU/day]
end

"""
Keplerian state: orbital elements + epoch. Useful for propagation shortcuts.
"""
struct KeplerianState
    t        :: Float64
    elements :: OrbitalElements
end

"""
Sail configuration at an instant.
α = cone angle from sun-direction [rad]
δ = clock angle [rad]
"""
struct SailAttitude
    α :: Float64
    δ :: Float64
end

"""
A trajectory leg between two events.
Stores enough to reconstruct the arc and compute ΔV / score contributions.
"""
@enum LegType begin
    LEG_COAST          # ballistic / Keplerian coast
    LEG_SAIL           # solar-sail arc
    LEG_PATCHED_CONIC  # hyperbolic flyby approximation
end

struct Leg
    type       :: LegType
    t_depart   :: Float64
    t_arrive   :: Float64
    state_dep  :: CartesianState
    state_arr  :: CartesianState
    # For sail legs: sampled attitude profile (can be empty for coast)
    attitudes  :: Vector{SailAttitude}
    # Residuals / feasibility flag from local solver
    feasible   :: Bool
    residual   :: Float64   # e.g. |Δv| or constraint violation
end
