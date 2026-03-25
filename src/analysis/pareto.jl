"""
Pareto front analysis: score vs. compute time, or score vs. sequence length.
"""

function pareto_front(results::Vector{BeamSearchResult})
    # Sort by score, then filter dominated by time
    sorted = sort(results, by=r -> -r.best_score)
    front = BeamSearchResult[]
    best_time = Inf
    for r in sorted
        if r.elapsed_seconds < best_time
            push!(front, r)
            best_time = r.elapsed_seconds
        end
    end
    return front
end
