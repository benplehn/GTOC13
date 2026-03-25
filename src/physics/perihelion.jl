"""
Perihelion detection and classification.
"""

"""
True if this event qualifies as a deep perihelion (r < R_DEEP_PERIHELION).
"""
function is_deep_perihelion(r_norm::Float64)
    return r_norm < R_DEEP_PERIHELION
end

"""
True if this event qualifies as a standard perihelion (r < R_NORMAL_PERIHELION).
"""
function is_perihelion(r_norm::Float64)
    return r_norm < R_NORMAL_PERIHELION
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
