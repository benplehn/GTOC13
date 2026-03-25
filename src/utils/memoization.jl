"""
Memoization helpers for expensive recurring computations
(e.g. Lambert solutions, encounter windows, Kepler propagation).
"""

"""
Memoized Kepler propagation: cache (elements, t) → (r, v).
"""
const _kepler_cache = Dict{Tuple{OrbitalElements, Float64}, Tuple{SVector{3,Float64}, SVector{3,Float64}}}()

function cached_kepler_propagate(el::OrbitalElements, t::Float64, μ::Float64)
    key = (el, t)
    haskey(_kepler_cache, key) && return _kepler_cache[key]
    result = kepler_propagate(el, t, μ)
    _kepler_cache[key] = result
    return result
end

"""
Clear all caches (call between runs to avoid stale data).
"""
function clear_caches!()
    empty!(_kepler_cache)
end
