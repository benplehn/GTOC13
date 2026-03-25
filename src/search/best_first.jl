"""
Best-first search (A*-style) guided by score_ub.

Unlike beam search, keeps ALL non-pruned nodes in a priority queue.
More memory-intensive but complete: will find the optimum if bounds are admissible.

Use this to:
  1. Verify beam search is not missing important solutions.
  2. Measure the true gap between admissible bound and optimum.
  3. Run on small instances to calibrate beam width.
"""

"""
Run best-first search from a root node.
Expand nodes in order of decreasing score_ub.
"""
function best_first_search(root::BackboneNode,
                             bodies::Vector{Body},
                             μ::Float64,
                             config::BeamSearchConfig;
                             node_limit::Int=100_000)
    # Priority queue: (−score_ub, node)
    # Julia DataStructures.PriorityQueue or manual heap
    # TODO: implement with DataStructures.jl
    @warn "best_first_search not yet implemented"
    return nothing
end
