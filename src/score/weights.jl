"""
Score weight lookup.
Constants are in physics/constants.jl (BODY_WEIGHTS).
This file provides the lookup API and handles asteroid/comet ranges.
"""

function body_weight(body_id::Int)
    haskey(BODY_WEIGHTS, body_id) && return BODY_WEIGHTS[body_id]
    ASTEROID_ID_MIN ≤ body_id ≤ ASTEROID_ID_MAX && return 1.0
    COMET_ID_MIN    ≤ body_id ≤ COMET_ID_MAX    && return 3.0
    error("Unknown body_id: $body_id")
end

function is_planet(body_id::Int)
    return PLANET_ID_MIN ≤ body_id ≤ PLANET_ID_MAX
end

function is_massless(body_id::Int)
    return body_id == YANDI_ID ||
           ASTEROID_ID_MIN ≤ body_id ≤ ASTEROID_ID_MAX ||
           COMET_ID_MIN    ≤ body_id ≤ COMET_ID_MAX
end
