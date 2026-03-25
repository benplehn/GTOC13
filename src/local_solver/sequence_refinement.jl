"""
Sequence refinement: given a feasible backbone, optimize event times
and sail attitudes to maximize score or minimize cost.

Phase 7+ concern. Stub for now.
"""

function refine_sequence(events::Vector{Event}, bodies::Vector{Body},
                          μ::Float64, β::Float64)
    # TODO: NLP refinement of event times + sail profiles
    return events
end
