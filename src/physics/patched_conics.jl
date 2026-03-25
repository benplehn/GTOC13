"""
Patched-conic flyby model — exact formulation from GTOC13 Appendix I.

Conditions:
  x(tG⁻) = xP(tG)                   [position match]
  |v∞G+| = |v∞G-| = v∞              [V∞ magnitude conserved]
  v∞G+ · v∞G- = v∞² cos(δt)         [turn angle]
  sin(δt/2) = (μP / rP) / (v∞² + μP / rP)   [where rP = RP + hpP]

Altitude constraint: 0.1·RP ≤ hpP ≤ 100·RP
"""

"""
Compute the turn angle δt [rad] for a flyby at periapsis distance rP = RP + hpP.
  v_inf  : hyperbolic excess speed [AU/day]
  r_p    : periapsis distance from planet center [AU]  (= RP + hpP)
  μ_body : planet gravitational parameter [AU³/day²]
"""
function flyby_turn_angle(v_inf::Float64, r_p::Float64, μ_body::Float64)
    # sin(δt/2) = (μP/rP) / (v∞² + μP/rP)
    x = μ_body / r_p
    sin_half = x / (v_inf^2 + x)
    return 2.0 * asin(clamp(sin_half, -1.0, 1.0))
end

"""
Maximum turn angle achievable at a planet, given incoming v_inf.
Achieved at minimum periapsis altitude (0.1·RP).
"""
function max_turn_angle(v_inf::Float64, R_body::Float64, μ_body::Float64)
    r_p_min = (1.0 + FLYBY_ALT_MIN_RADII) * R_body
    return flyby_turn_angle(v_inf, r_p_min, μ_body)
end

"""
Minimum periapsis distance [AU] needed to achieve turn angle δt [rad].
"""
function min_periapsis_for_turn(δt::Float64, v_inf::Float64, μ_body::Float64)
    # From sin(δt/2) = (μ/rP)/(v∞² + μ/rP) → rP = μ/(v∞² * sin(δt/2)/(1-sin(δt/2)))
    s = sin(δt / 2.0)
    s >= 1.0 && return 0.0
    return μ_body * (1.0 - s) / (v_inf^2 * s)
end

"""
Given incoming V∞ vector v_in_inf and desired turn angle δt,
return the family of achievable outgoing V∞ vectors parameterized by
clock angle φ ∈ [0, 2π).

Returns a function φ → v_out_inf [same units as v_in_inf].
"""
function flyby_v_out_family(v_in_inf::SVector{3,Float64}, δt::Float64)
    v_n   = norm(v_in_inf)
    v_hat = v_in_inf / v_n
    # Two orthogonal vectors perpendicular to v_hat
    basis = abs(v_hat[1]) < 0.9 ? SVector(1.0, 0.0, 0.0) : SVector(0.0, 1.0, 0.0)
    e1 = normalize(basis - dot(basis, v_hat) * v_hat)
    e2 = cross(v_hat, e1)
    return φ -> v_n * (cos(δt) * v_hat + sin(δt) * (cos(φ) * e1 + sin(φ) * e2))
end

"""
Compute the flyby periapsis altitude [AU] from v_inf and periapsis distance.
"""
function flyby_altitude(r_p::Float64, R_body::Float64)
    return r_p - R_body
end

"""
Check if a flyby altitude satisfies the statement constraints.
"""
function flyby_altitude_feasible(r_p::Float64, R_body::Float64)
    alt = flyby_altitude(r_p, R_body)
    return FLYBY_ALT_MIN_RADII * R_body ≤ alt ≤ FLYBY_ALT_MAX_RADII * R_body
end
