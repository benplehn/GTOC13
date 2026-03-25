"""
Keplerian propagation primitives.

All angles in radians, distances in AU, times in days.
"""

"""
Solve Kepler's equation M = E - e*sin(E) for E given M, e.
Newton-Raphson with fallback for high eccentricity.
"""
function solve_kepler(M::Float64, e::Float64; tol::Float64=1e-12, maxiter::Int=50)
    E = M + e * sin(M)   # initial guess
    for _ in 1:maxiter
        dE = (M - E + e * sin(E)) / (1.0 - e * cos(E))
        E += dE
        abs(dE) < tol && return E
    end
    error("Kepler solver did not converge: M=$M, e=$e")
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
    return sqrt(μ / a^3)
end

"""
Propagate OrbitalElements from epoch t0 to time t.
Returns (r [AU], v [AU/day]) in the orbital plane (perifocal frame).
Call `perifocal_to_inertial` to get 3D vectors.
"""
function kepler_propagate(el::OrbitalElements, t::Float64, μ::Float64)
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
    cΩ, sΩ = cos(Ω), sin(Ω)
    cω, sω = cos(ω), sin(ω)
    ci, si = cos(i), sin(i)
    return SMatrix{3,3}(
        cΩ*cω - sΩ*sω*ci,  -cΩ*sω - sΩ*cω*ci,  sΩ*si,
        sΩ*cω + cΩ*sω*ci,  -sΩ*sω + cΩ*cω*ci, -cΩ*si,
        sω*si,               cω*si,               ci
    )
end

"""
Propagate a CartesianState forward by Δt days using Keplerian dynamics.
Raises if orbit is hyperbolic (e ≥ 1).
"""
function propagate_state(s::CartesianState, Δt::Float64, μ::Float64)
    el = state_to_elements(s, μ)
    r, v = kepler_propagate(el, s.t + Δt, μ)
    return CartesianState(s.t + Δt, r, v)
end

"""
Convert (r, v) at time t to OrbitalElements.
"""
function state_to_elements(s::CartesianState, μ::Float64)
    r, v = s.r, s.v
    r_n = norm(r)
    v_n = norm(v)
    h   = cross(r, v)
    h_n = norm(h)
    e_vec = (v_n^2 / μ - 1.0 / r_n) .* r .- (dot(r, v) / μ) .* v
    e = norm(e_vec)
    E_vis = v_n^2 / 2 - μ / r_n
    a = -μ / (2 * E_vis)
    i = acos(clamp(h[3] / h_n, -1.0, 1.0))
    N = cross(SVector(0.0, 0.0, 1.0), h)
    N_n = norm(N)
    Ω = N_n < 1e-15 ? 0.0 : (N[2] >= 0 ? acos(clamp(N[1]/N_n,-1,1)) : 2π - acos(clamp(N[1]/N_n,-1,1)))
    ω = if N_n < 1e-15 || e < 1e-12
        0.0
    else
        ang = acos(clamp(dot(N, e_vec) / (N_n * e), -1.0, 1.0))
        e_vec[3] >= 0 ? ang : 2π - ang
    end
    ν = if e < 1e-12
        ang = acos(clamp(dot(N, r) / (N_n * r_n), -1.0, 1.0))
        dot(r, v) >= 0 ? ang : 2π - ang
    else
        ang = acos(clamp(dot(e_vec, r) / (e * r_n), -1.0, 1.0))
        dot(r, v) >= 0 ? ang : 2π - ang
    end
    M_from_E = begin
        cosE = (a - r_n) / (a * e)
        E_val = acos(clamp(cosE, -1.0, 1.0))
        dot(r, v) < 0 && (E_val = 2π - E_val)
        E_val - e * sin(E_val)
    end
    return OrbitalElements(a, e, i, Ω, ω, M_from_E, s.t)
end
