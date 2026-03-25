"""
Solar sail acceleration model — exact formulation from GTOC13 §5.

Ideal sail (perfect mirror):
  a_sail = -(2C·A/m) · (r0/r)² · (û_n · û_r)² · û_n

where:
  C  = Altaira flux at 1 AU = 5.4026e-6 N/m²
  A  = 15000 m²
  m  = 500 kg
  r0 = 1 AU
  û_r = unit vector from spacecraft to Altaira (i.e. -r̂)
  û_n = sail normal (must satisfy û_n · û_r ≥ 0, so cone angle α ∈ [0°, 90°])
  α   = angle between û_n and û_r

Constraint: no radially inward acceleration component.
α ∈ [0°, 90°]: α=0 → full sail toward sun, α=90° → sail edge-on (no force).
"""

using LinearAlgebra

# Characteristic acceleration at 1 AU in km/s²
const A_CHAR_KM_S2 = 2.0 * SAIL_C_SI * SAIL_AREA / SAIL_MASS * 1e-3  # [km/s²]

# Characteristic acceleration in AU/day²
const A_CHAR_AU_DAY2 = kms2_to_auday2(A_CHAR_KM_S2)  # [AU/day²]

sail_cone_angle_in_domain(α::Float64) = 0.0 ≤ α ≤ (π / 2.0)

function require_sail_cone_angle_in_domain(α::Float64)
    sail_cone_angle_in_domain(α) && return true
    error("Sail cone angle α=$(α) rad is outside the allowed domain [0, π/2]")
end

"""
Compute sail acceleration vector [AU/day²] given:
  r     : spacecraft heliocentric position [AU]
  u_n   : sail normal unit vector (must satisfy u_n · (-r̂) ≥ 0)
"""
function sail_acceleration(r::SVector{3,Float64}, u_n::SVector{3,Float64})
    require_distance_au(r; name="sail position")
    r_norm = norm(r)
    r_hat  = r / r_norm          # points away from Altaira
    u_r    = -r_hat              # points toward Altaira (from statement: û_r from SC to Altaira)

    cos_α  = dot(u_n, u_r)
    # Enforce constraint: cos_α must be ≥ 0 (α ∈ [0, 90°])
    cos_α  = max(cos_α, 0.0)

    # a_sail = -(2C·A/m)(r0/r)² cos²(α) û_n  [in SI, then convert]
    # Sign from statement: a_sail = -(û_n·û_r)² û_n  scaled by 2CA/m·(r0/r)²
    # The minus sign + u_r pointing inward means the force is always outward or lateral.
    scale = A_CHAR_AU_DAY2 * (1.0 / r_norm)^2 * cos_α^2
    return -scale .* u_n
end

"""
Sail normal unit vector from cone angle α [rad] and clock angle δ [rad],
expressed in the local radial-transverse-normal (RTN) frame, then rotated
to inertial frame.
  α ∈ [0, π/2]
  δ ∈ [0, 2π)
"""
function sail_normal_from_angles(r::SVector{3,Float64}, v::SVector{3,Float64},
                                  α::Float64, δ::Float64)
    require_sail_cone_angle_in_domain(α)
    require_angle_radians(δ; name="clock angle", lower=0.0, upper=TWO_PI)
    require_distance_au(r; name="sail frame position")
    require_velocity_auday(v; name="sail frame velocity")
    r_norm = norm(r)
    h = cross(r, v)
    norm(h) > 1e-15 || error("Cannot define sail frame from collinear position and velocity")

    r_hat = r / r_norm
    h_hat = h / norm(h)
    t_hat = cross(h_hat, r_hat)

    # û_r (toward Altaira) = -r̂ in RTN
    # û_n in RTN: cone angle α from û_r, clock angle δ
    # û_n = cos(α)·(-r̂) + sin(α)·(cos(δ)·t̂ + sin(δ)·ĥ)
    u_n = cos(α) .* (-r_hat) .+ sin(α) .* (cos(δ) .* t_hat .+ sin(δ) .* h_hat)
    return u_n / norm(u_n)
end

"""
Effective gravitational parameter for radial sail (α=0, full thrust against sun):
  μ_eff = μ * (1 - β)
where β = SAIL_BETA is the sail lightness number.
"""
function effective_mu_radial(μ::Float64)
    return μ * (1.0 - SAIL_BETA)
end
