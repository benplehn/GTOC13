"""
Reference frame utilities.

GTOC13 frame convention from the statement:
  - z-axis: Vulcan orbital angular momentum
  - x-axis: initial spacecraft velocity direction toward Altaira
  - y-axis: z × x
"""

struct ReferenceFrame
    x̂ :: SVector{3,Float64}
    ŷ :: SVector{3,Float64}
    ẑ :: SVector{3,Float64}

    function ReferenceFrame(x̂::SVector{3,Float64}, ŷ::SVector{3,Float64}, ẑ::SVector{3,Float64})
        all(isfinite, x̂) || error("Frame x-axis must be finite")
        all(isfinite, ŷ) || error("Frame y-axis must be finite")
        all(isfinite, ẑ) || error("Frame z-axis must be finite")

        isapprox(norm(x̂), 1.0; atol=1e-10, rtol=0.0) || error("Frame x-axis must be unit-norm")
        isapprox(norm(ŷ), 1.0; atol=1e-10, rtol=0.0) || error("Frame y-axis must be unit-norm")
        isapprox(norm(ẑ), 1.0; atol=1e-10, rtol=0.0) || error("Frame z-axis must be unit-norm")

        abs(dot(x̂, ŷ)) ≤ 1e-10 || error("Frame axes x and y must be orthogonal")
        abs(dot(x̂, ẑ)) ≤ 1e-10 || error("Frame axes x and z must be orthogonal")
        abs(dot(ŷ, ẑ)) ≤ 1e-10 || error("Frame axes y and z must be orthogonal")
        isapprox(cross(ẑ, x̂), ŷ; atol=1e-10, rtol=0.0) ||
            error("Frame must satisfy y = z × x")
        isapprox(dot(cross(x̂, ŷ), ẑ), 1.0; atol=1e-10, rtol=0.0) ||
            error("Frame must be direct with x × y = z")

        new(x̂, ŷ, ẑ)
    end
end

function vulcan_orbital_pole(vulcan_state::CartesianState)
    pole = safe_normalize(cross(vulcan_state.r, vulcan_state.v))
    norm(pole) > 0.0 || error("Cannot define Vulcan orbital pole from degenerate state")
    return pole
end

function gtoc13_reference_frame(vulcan_state::CartesianState,
                                initial_velocity_toward_altaira::SVector{3,Float64};
                                orthogonality_tol::Float64=1e-10)
    ẑ = vulcan_orbital_pole(vulcan_state)
    x̂ = safe_normalize(initial_velocity_toward_altaira)
    norm(x̂) > 0.0 || error("Initial spacecraft velocity direction must be nonzero")
    abs(dot(x̂, ẑ)) ≤ orthogonality_tol ||
        error("Initial spacecraft velocity direction must lie in the Vulcan ecliptic plane")
    ŷ = safe_normalize(cross(ẑ, x̂))
    return ReferenceFrame(x̂, ŷ, ẑ)
end

function gtoc13_reference_frame(vulcan::Body,
                                initial_velocity_toward_altaira::SVector{3,Float64};
                                t::Float64=T_LAUNCH_JD,
                                μ_central::Float64=MU_ALTAIRA,
                                orthogonality_tol::Float64=1e-10)
    vulcan.id == ID_VULCAN || error("GTOC13 frame must be anchored on Vulcan (body id $(ID_VULCAN))")
    supports_massive_flyby(vulcan) || error("Reference frame anchor must be a massive planet")
    r, v = kepler_propagate(vulcan.elements, t, μ_central)
    state = CartesianState(t, r, v)
    return gtoc13_reference_frame(state, initial_velocity_toward_altaira;
                                  orthogonality_tol=orthogonality_tol)
end

function initial_epoch_days(t0_years::Real)
    t0 = float(t0_years)
    0.0 ≤ t0 ≤ T_MISSION_YEARS || error("Initial epoch t0=$(t0) years must lie in [0, $(T_MISSION_YEARS)]")
    return years_to_days(t0)
end

function initial_spacecraft_state(t0_years::Real;
                                  y0_au::Real=0.0,
                                  z0_au::Real=0.0,
                                  vx_auday::Real=0.0)
    t_days = initial_epoch_days(t0_years)
    return CartesianState(
        t_days,
        SVector(SC_INITIAL_X, float(y0_au), float(z0_au)),
        SVector(float(vx_auday), SC_INITIAL_VY, SC_INITIAL_VZ),
    )
end

"""
Heliocentric direction unit vector from spacecraft position.
"""
function heliocentric_direction(r::SVector{3,Float64})
    return r / norm(r)
end

"""
Ecliptic longitude and latitude [rad] from a position vector.
"""
function ecliptic_lon_lat(r::SVector{3,Float64})
    r_hat = r / norm(r)
    lat = asin(clamp(r_hat[3], -1.0, 1.0))
    lon = atan(r_hat[2], r_hat[1])
    return lon, lat
end
