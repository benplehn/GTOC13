"""
All celestial body representations used throughout the solver.
"""

@enum BodyClass begin
    STAR          # Altaira
    PLANET        # massive flyby candidate
    ASTEROID      # massless encounter candidate
    COMET         # massless encounter candidate (Yandi + others)
    MOON          # not expected, but reserved
end

@enum BodyId begin
    ALTAIRA
    VULCAN
    TERRA
    OCEANUS
    ZEUS
    YANDI          # the named comet
    # small bodies are indexed dynamically
end

"""
Keplerian orbital elements at a reference epoch.
Semi-major axis in AU, angles in radians, time in Julian days.
"""
struct OrbitalElements
    a   :: Float64   # semi-major axis [AU]
    e   :: Float64   # eccentricity
    i   :: Float64   # inclination [rad]
    Ω   :: Float64   # longitude of ascending node [rad]
    ω   :: Float64   # argument of periapsis [rad]
    M0  :: Float64   # mean anomaly at epoch [rad]
    t0  :: Float64   # reference epoch [JD]

    function OrbitalElements(a::Float64, e::Float64, i::Float64, Ω::Float64,
                             ω::Float64, M0::Float64, t0::Float64)
        require_distance_au(a; name="semi-major axis", positive=true)
        require_finite_scalar(e; name="eccentricity")
        0.0 ≤ e < 1.0 || error("eccentricity=$(e) is outside the elliptic range [0, 1)")
        require_angle_radians(i; name="inclination", lower=0.0, upper=π)
        require_angle_radians(Ω; name="longitude of ascending node", lower=0.0, upper=TWO_PI)
        require_angle_radians(ω; name="argument of periapsis", lower=0.0, upper=TWO_PI)
        require_angle_radians(M0; name="mean anomaly", lower=0.0, upper=TWO_PI)
        require_finite_scalar(t0; name="reference epoch")
        new(a, e, i, Ω, ω, M0, t0)
    end
end

"""
A body with fixed Keplerian elements (valid when perturbations are negligible
over the mission window — revisit if needed).
"""
struct Body
    id       :: Int          # unique integer index into global body table
    name     :: String
    class    :: BodyClass
    μ        :: Float64      # gravitational parameter [AU³/day²], 0 for massless
    R        :: Float64      # mean radius [AU], used for SOI / encounter check
    elements :: OrbitalElements
    # Score metadata
    w_body   :: Float64      # base score weight for this body (from statement)
end

"""
A precomputed ephemeris segment: state vectors at discrete times.
Used when Keplerian propagation is insufficient (e.g. Altaira perturbations).
"""
struct EphemerisSegment
    body_id    :: Int
    t_start    :: Float64     # [JD]
    t_end      :: Float64     # [JD]
    dt         :: Float64     # step [days]
    positions  :: Matrix{Float64}   # 3 × N [AU]
    velocities :: Matrix{Float64}   # 3 × N [AU/day]
end

"""
True when the body can provide an ephemeris to the solver.
For section 1, fixed orbital elements count as a valid ephemeris source.
"""
function has_ephemeris_source(body::Body)
    return isfinite(body.elements.a) && body.elements.a > 0.0
end

"""
True for bodies that can generate a patched-conic flyby.
"""
function supports_massive_flyby(body::Body)
    return body.class == PLANET && body.μ > 0.0
end

"""
True for bodies that can only be used as massless encounters.
"""
function supports_massless_encounter(body::Body)
    return is_massless(body.id)
end

"""
Orbital period around Altaira in days, under the Keplerian approximation.
"""
function orbital_period(body::Body; μ_central::Float64=MU_ALTAIRA)
    return 2π / mean_motion(body.elements.a, μ_central)
end

"""
Minimum allowed separation between two flybys of the same body.
"""
function minimum_reflyby_separation(body::Body; μ_central::Float64=MU_ALTAIRA)
    return REFLYBY_PERIOD_FRACTION * orbital_period(body; μ_central=μ_central)
end

"""
True if two flybys of the same body are sufficiently separated in time.
"""
function flyby_revisit_allowed(body::Body, t_prev::Float64, t_next::Float64;
                               μ_central::Float64=MU_ALTAIRA)
    t_next < t_prev && error("Encounter times must be nondecreasing for body $(body.id)")
    return (t_next - t_prev) ≥ minimum_reflyby_separation(body; μ_central=μ_central)
end

"""
Throw an explicit error if the revisit-spacing rule is violated.
"""
function require_flyby_revisit_spacing(body::Body, t_prev::Float64, t_next::Float64;
                                       μ_central::Float64=MU_ALTAIRA)
    flyby_revisit_allowed(body, t_prev, t_next; μ_central=μ_central) && return true
    Δt_min = minimum_reflyby_separation(body; μ_central=μ_central)
    error("Flybys of body $(body.id) must be separated by at least $(Δt_min) days")
end
