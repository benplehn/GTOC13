"""
Interpolation utilities for ephemeris lookup.
"""

"""
Linear interpolation of a 3×N matrix at time t, given times grid.
"""
function interp_state(times::Vector{Float64}, states::Matrix{Float64},
                       t::Float64)
    i = searchsortedlast(times, t)
    i = clamp(i, 1, length(times) - 1)
    α = (t - times[i]) / (times[i+1] - times[i])
    return (1 - α) .* states[:, i] .+ α .* states[:, i+1]
end
