"""
Keplerian propagation primitives.

All angles in radians, distances in AU, times in days.
"""

"""
Solve Kepler's equation M = E - e*sin(E) for E given M, e.
Bracketed Newton iteration on a reduced anomaly, then reconstruction by 2π turns.
"""
function solve_kepler_diagnostics(M::Float64, e::Float64; tol::Float64=1e-12, maxiter::Int=50)
    require_finite_scalar(M; name="mean anomaly")
    require_finite_scalar(e; name="eccentricity")
    0.0 ≤ e < 1.0 || error("eccentricity=$(e) is outside the elliptic range [0, 1)")
    tol > 0.0 || error("Kepler tolerance must be positive")
    maxiter > 0 || error("Kepler maxiter must be positive")

    if e == 0.0
        return (E=M, iterations=0, residual=0.0)
    end

    M_reduced = mod(M + π, TWO_PI) - π
    k_turns = round(Int, (M - M_reduced) / TWO_PI)

    lo = -π
    hi = π
    E = if e < 0.8
        M_reduced + e * sin(M_reduced)
    elseif M_reduced == 0.0
        0.0
    else
        M_reduced + 0.85 * sign(M_reduced) * e
    end
    E = clamp(E, lo, hi)

    for iter in 1:maxiter
        f = E - e * sin(E) - M_reduced
        abs(f) < tol && return (E=E + k_turns * TWO_PI, iterations=iter, residual=abs(f))

        if f > 0.0
            hi = E
        else
            lo = E
        end

        fp = 1.0 - e * cos(E)
        E_trial = E - f / fp
        if !isfinite(E_trial) || E_trial ≤ lo || E_trial ≥ hi
            E_trial = 0.5 * (lo + hi)
        end
        E = E_trial
    end

    error("Kepler solver did not converge within $(maxiter) iterations: M=$M, e=$e")
end

function solve_kepler(M::Float64, e::Float64; tol::Float64=1e-12, maxiter::Int=50)
    return solve_kepler_diagnostics(M, e; tol=tol, maxiter=maxiter).E
end

"""
True anomaly from eccentric anomaly.
"""
function eccentric_to_true(E::Float64, e::Float64)
    return 2.0 * atan(sqrt((1 + e) / (1 - e)) * tan(E / 2.0))
end

"""
Mean motion [rad/day] from semi-major axis [AU] and μ [AU³/day²].
"""
function mean_motion(a::Float64, μ::Float64)
    require_distance_au(a; name="semi-major axis", positive=true)
    require_positive_mu_au3day2(μ)
    return sqrt(μ / a^3)
end

"""
Propagate OrbitalElements from epoch t0 to time t.
Returns (r [AU], v [AU/day]) in the orbital plane (perifocal frame).
Call `perifocal_to_inertial` to get 3D vectors.
"""
function kepler_propagate(el::OrbitalElements, t::Float64, μ::Float64)
    require_finite_scalar(t; name="propagation time")
    require_positive_mu_au3day2(μ)
    n  = mean_motion(el.a, μ)
    M  = mod(el.M0 + n * (t - el.t0), 2π)
    E  = solve_kepler(M, el.e)
    ν  = eccentric_to_true(E, el.e)

    p  = el.a * (1 - el.e^2)
    r_norm = p / (1 + el.e * cos(ν))

    # Perifocal position and velocity
    r_peri = SVector(r_norm * cos(ν), r_norm * sin(ν), 0.0)
    v_peri = SVector(-sqrt(μ / p) * sin(ν), sqrt(μ / p) * (el.e + cos(ν)), 0.0)

    # Rotate to inertial frame
    R = perifocal_rotation(el.Ω, el.ω, el.i)
    return R * r_peri, R * v_peri
end

"""
3×3 rotation matrix from perifocal to inertial (J2000 ecliptic).
"""
function perifocal_rotation(Ω::Float64, ω::Float64, i::Float64)
    require_angle_radians(Ω; name="longitude of ascending node", lower=0.0, upper=TWO_PI)
    require_angle_radians(ω; name="argument of periapsis", lower=0.0, upper=TWO_PI)
    require_angle_radians(i; name="inclination", lower=0.0, upper=π)
    cΩ, sΩ = cos(Ω), sin(Ω)
    cω, sω = cos(ω), sin(ω)
    ci, si = cos(i), sin(i)
    return @SMatrix [
        cΩ*cω - sΩ*sω*ci   -cΩ*sω - sΩ*cω*ci    sΩ*si
        sΩ*cω + cΩ*sω*ci   -sΩ*sω + cΩ*cω*ci   -cΩ*si
        sω*si               cω*si                ci
    ]
end

"""
Propagate a CartesianState forward by Δt days using Keplerian dynamics.
Raises if orbit is hyperbolic (e ≥ 1).
"""
function propagate_state(s::CartesianState, Δt::Float64, μ::Float64)
    require_finite_scalar(Δt; name="propagation duration")
    require_positive_mu_au3day2(μ)
    el = state_to_elements(s, μ)
    r, v = kepler_propagate(el, s.t + Δt, μ)
    return CartesianState(s.t + Δt, r, v)
end

"""
Convert (r, v) at time t to OrbitalElements.
"""
function state_to_elements(s::CartesianState, μ::Float64)
    require_positive_mu_au3day2(μ)
    r, v = s.r, s.v
    r_n = norm(r)
    v_n = norm(v)
    h   = cross(r, v)
    h_n = norm(h)
    e_vec = ((v_n^2 - μ / r_n) .* r - dot(r, v) .* v) / μ
    e = norm(e_vec)
    a = 1.0 / (2.0 / r_n - v_n^2 / μ)
    i = acos(clamp(h[3] / h_n, -1.0, 1.0))
    n_vec = cross(SVector(0.0, 0.0, 1.0), h)
    n_n = norm(n_vec)

    Ω = n_n < 1e-15 ? 0.0 : mod(atan(n_vec[2], n_vec[1]), 2π)

    ω, ν = if e < 1e-12 && n_n < 1e-15
        0.0, mod(atan(r[2], r[1]), 2π)
    elseif e < 1e-12
        u = mod(
            atan(dot(cross(n_vec, r), h) / (n_n * h_n * r_n),
                 dot(n_vec, r) / (n_n * r_n)),
            2π,
        )
        0.0, u
    elseif n_n < 1e-15
        ϖ = mod(atan(e_vec[2], e_vec[1]), 2π)
        ν_val = mod(
            atan(dot(cross(e_vec, r), h) / (e * h_n * r_n),
                 dot(e_vec, r) / (e * r_n)),
            2π,
        )
        ϖ, ν_val
    else
        ω_val = mod(
            atan(dot(cross(n_vec, e_vec), h) / (n_n * h_n * e),
                 dot(n_vec, e_vec) / (n_n * e)),
            2π,
        )
        ν_val = mod(
            atan(dot(cross(e_vec, r), h) / (e * h_n * r_n),
                 dot(e_vec, r) / (e * r_n)),
            2π,
        )
        ω_val, ν_val
    end

    M_from_E = if e < 1e-12
        ν
    else
        E_val = 2.0 * atan(sqrt((1.0 - e) / (1.0 + e)) * tan(ν / 2.0))
        mod(E_val - e * sin(E_val), 2π)
    end
    return OrbitalElements(a, e, i, Ω, ω, M_from_E, s.t)
end
