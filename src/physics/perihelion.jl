"""
Perihelion detection and classification.
"""

"""
True if this event qualifies as a deep perihelion (r < R_DEEP_PERIHELION).
"""
function is_deep_perihelion(r_norm::Float64; tol_au::Float64=PERIHELION_CHECKER_TOL_AU)
    return (R_DEEP_PERIHELION - tol_au) ≤ r_norm < (R_NORMAL_PERIHELION - tol_au)
end

"""
True if this event qualifies as a standard perihelion (r < R_NORMAL_PERIHELION).
"""
function is_perihelion(r_norm::Float64; tol_au::Float64=PERIHELION_CHECKER_TOL_AU)
    return r_norm < (R_NORMAL_PERIHELION - tol_au)
end

"""
Classify a perihelion radius against the problem rules.

Returns one of:
  - `:nominal` for r_p >= 0.05 AU
  - `:deep` for 0.01 AU <= r_p < 0.05 AU when the deep slot is still free
  - `:invalid` otherwise
"""
function classify_perihelion_radius(r_norm::Float64, resources::MissionResources;
                                    tol_au::Float64=PERIHELION_CHECKER_TOL_AU)
    require_finite_scalar(r_norm; name="perihelion radius")
    r_norm < (R_DEEP_PERIHELION - tol_au) && return :invalid
    r_norm ≥ (R_NORMAL_PERIHELION - tol_au) && return :nominal
    return resources.deep_perihelion_used ? :invalid : :deep
end

"""
True if the perihelion radius respects the mission rules.
"""
function perihelion_radius_allowed(r_norm::Float64, resources::MissionResources;
                                   tol_au::Float64=PERIHELION_CHECKER_TOL_AU)
    return classify_perihelion_radius(r_norm, resources; tol_au=tol_au) != :invalid
end

"""
Throw an explicit error if the perihelion radius violates the mission rules.
"""
function require_perihelion_radius_allowed(r_norm::Float64, resources::MissionResources;
                                           tol_au::Float64=PERIHELION_CHECKER_TOL_AU)
    status = classify_perihelion_radius(r_norm, resources; tol_au=tol_au)
    status != :invalid && return status

    if r_norm < (R_DEEP_PERIHELION - tol_au)
        error("Perihelion radius $(r_norm) AU is below the absolute minimum of $(R_DEEP_PERIHELION) AU")
    end

    error("Deep perihelion slot has already been consumed")
end

"""
Estimate the perihelion time given two bracketing states (bisection stub).
"""
function find_perihelion_time(s1::CartesianState, s2::CartesianState, μ::Float64;
                               tol::Float64=1e-6)
    s2.t < s1.t && error("Invalid perihelion bracket: t2 < t1")
    abs(s2.t - s1.t) ≤ tol && return s1.t

    lo = s1.t
    hi = s2.t

    for _ in 1:80
        (hi - lo) ≤ tol && break
        t_left = lo + (hi - lo) / 3.0
        t_right = hi - (hi - lo) / 3.0

        r_left = norm(propagate_state(s1, t_left - s1.t, μ).r)
        r_right = norm(propagate_state(s1, t_right - s1.t, μ).r)

        if r_left ≤ r_right
            hi = t_right
        else
            lo = t_left
        end
    end

    return 0.5 * (lo + hi)
end
