"""
Centralized unit conversions and lightweight input validation.

Internal conventions for the solver core:
  - distance: AU
  - time: days
  - speed: AU/day
  - acceleration: AU/day^2
  - angles: radians
  - gravitational parameter: AU^3/day^2
"""

const TWO_PI = 2.0 * π
const MAX_REASONABLE_AU = 1.0e3
const MAX_REASONABLE_AU_PER_DAY = 10.0
const ANGLE_GUARD_EPS = 1e-12

km_to_au(x::Real) = float(x) * KM_TO_AU
au_to_km(x::Real) = float(x) * AU_KM

seconds_to_days(x::Real) = float(x) / DAY_S
days_to_seconds(x::Real) = float(x) * DAY_S

years_to_days(x::Real) = float(x) * YEAR_DAYS
days_to_years(x::Real) = float(x) / YEAR_DAYS

deg_to_rad(x::Real) = float(x) * DEG2RAD
rad_to_deg(x::Real) = float(x) / DEG2RAD

kms_to_auday(x::Real) = float(x) * DAY_S * KM_TO_AU
auday_to_kms(x::Real) = float(x) * AU_KM / DAY_S

kms2_to_auday2(x::Real) = float(x) * DAY_S^2 * KM_TO_AU
auday2_to_kms2(x::Real) = float(x) * AU_KM / DAY_S^2

μ_km3s2_to_au3day2(x::Real) = float(x) * KM3S2_TO_AU3DAY2
μ_au3day2_to_km3s2(x::Real) = float(x) / KM3S2_TO_AU3DAY2

function require_finite_scalar(x::Real; name::String="value")
    isfinite(float(x)) || error("$(name) must be finite")
    return true
end

function require_angle_radians(x::Real; name::String="angle",
                               lower::Real=0.0, upper::Real=TWO_PI)
    x_f = float(x)
    lower_f = float(lower)
    upper_f = float(upper)
    require_finite_scalar(x_f; name=name)
    lower_f - ANGLE_GUARD_EPS ≤ x_f ≤ upper_f + ANGLE_GUARD_EPS ||
        error("$(name)=$(x_f) is inconsistent with radians; expected in [$(lower_f), $(upper_f)]")
    return true
end

function require_distance_au(x::Real; name::String="distance",
                             positive::Bool=false, max_abs::Real=MAX_REASONABLE_AU)
    x_f = float(x)
    max_abs_f = float(max_abs)
    require_finite_scalar(x_f; name=name)
    positive && x_f <= 0.0 && error("$(name) must be positive in AU")
    abs(x_f) ≤ max_abs_f || error("$(name)=$(x_f) AU is implausibly large; check km vs AU")
    return true
end

function require_distance_au(r::SVector{3,Float64}; name::String="position",
                             min_norm::Float64=1e-12, max_norm::Float64=MAX_REASONABLE_AU)
    all(isfinite, r) || error("$(name) must be finite in AU")
    n = norm(r)
    n ≥ min_norm || error("$(name) norm is too close to zero for AU state dynamics")
    n ≤ max_norm || error("$(name) norm=$(n) AU is implausibly large; check km vs AU")
    return true
end

function require_velocity_auday(v::SVector{3,Float64}; name::String="velocity",
                                max_norm::Float64=MAX_REASONABLE_AU_PER_DAY)
    all(isfinite, v) || error("$(name) must be finite in AU/day")
    n = norm(v)
    n ≤ max_norm || error("$(name) norm=$(n) AU/day is implausibly large; check unit mismatch")
    return true
end

function require_positive_mu_au3day2(μ::Real; name::String="μ")
    μ_f = float(μ)
    require_finite_scalar(μ_f; name=name)
    μ_f > 0.0 || error("$(name) must be positive in AU^3/day^2")
    return true
end
