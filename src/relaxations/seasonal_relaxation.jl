"""
Relaxation of the seasonal factor S.

Treat S as a function of "angular coverage" on the unit sphere,
bounded above by a monotone function of the number of encounters.

This enables computing an upper bound on total body score
without simulating exact encounter directions.
"""

"""
Upper bound on the sum of S factors for n encounters with a body,
given the existing direction set (may be empty).

Key insight: each new encounter in a "new" angular bin scores S=1.
Overlapping encounters score less. The best case is perfectly spread directions.
"""
function seasonal_sum_upper_bound(existing_dirs::Vector{SVector{3,Float64}},
                                   n_future::Int)
    # V0: trivial bound — each encounter scores at most 1
    return Float64(n_future)
    # TODO: tighter bound using angular coverage model
end
