"""
Numerical utilities used across the solver.
"""

"""
Normalize a vector; return zero vector if near-zero (avoids NaN).
"""
function safe_normalize(v::SVector{3,Float64}; tol::Float64=1e-15)
    n = norm(v)
    n < tol && return SVector(0.0, 0.0, 0.0)
    return v / n
end

"""
Clamp an angle to [0, 2π).
"""
mod2pi_pos(θ::Float64) = mod(θ, 2π)

"""
Angle between two unit vectors [rad].
"""
angle_between(a::SVector{3,Float64}, b::SVector{3,Float64}) =
    acos(clamp(dot(a, b), -1.0, 1.0))
