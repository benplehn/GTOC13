"""
Seasonal penalty term S — exact formula from GTOC13 problem statement §3.3.

S(r̂_k,i) = 0.1 + 0.9 / (1 + 10 · Σ_{j=1}^{i-1} exp(-(acosd(r̂_k,i · r̂_k,j))² / 50))

where acosd returns degrees (0°–180°).

Properties:
  • S = 1 for the first encounter (i=1, empty sum).
  • S ≥ 0.1 always (floor).
  • S decreases when new direction is close to existing ones.
  • S ≈ 1 when new direction is far (≥ ~50°) from all previous.
"""

"""
Compute S for the i-th scientific flyby of a body, given:
  new_dir      : unit heliocentric position vector r̂_{k,i}
  prev_dirs    : unit vectors r̂_{k,1}, ..., r̂_{k,i-1}

Returns S ∈ [0.1, 1].
"""
function seasonal_factor(new_dir::SVector{3,Float64},
                          prev_dirs::Vector{SVector{3,Float64}})
    isempty(prev_dirs) && return 1.0
    sum_exp = 0.0
    for d in prev_dirs
        # acosd: arccosine in degrees
        cos_angle = clamp(dot(new_dir, d), -1.0, 1.0)
        angle_deg = acos(cos_angle) * (180.0 / π)
        sum_exp  += exp(-(angle_deg^2) / 50.0)
    end
    return 0.1 + 0.9 / (1.0 + 10.0 * sum_exp)
end

"""
Upper bound on the total Σ S_i for n_future additional encounters,
given existing direction set.

Tight bound: if all future encounters are perfectly spread (orthogonal),
each scores S → 1. So the trivial upper bound is n_future.

Tighter (but still admissible): use the angular coverage model.
The denominator of S grows by at least 10*exp(0)=10 per perfectly repeated
encounter. For a fully novel direction (angle > ~50°), contribution ≈ 0.
So for n_future encounters over a sufficiently diverse orbit, ≈ n_future.

V0: return n_future (trivially admissible).
"""
function seasonal_factor_upper_bound(prev_dirs::Vector{SVector{3,Float64}},
                                      n_future::Int)
    return Float64(n_future)
end
