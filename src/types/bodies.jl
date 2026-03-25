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
