"""
Cut pool: valid inequalities generated during search that prune future nodes.

A cut is a boolean predicate on a BackboneNode.
If cut(node) returns true, the node is infeasible / cannot beat incumbent.

Cuts here are "Benders-like": generated when a subproblem fails and
the failure reason can be encoded as a constraint on the master.
"""

abstract type SearchCut end

"""
A cut that prunes any node whose score_ub is below a threshold.
Trivial but useful as baseline.
"""
struct ScoreThresholdCut <: SearchCut
    threshold :: Float64
end

applies(cut::ScoreThresholdCut, node::BackboneNode) = node.score_ub < cut.threshold

"""
A cut encoding that a particular resource combination leads to infeasibility.
E.g., "deep perihelion consumed before planet X visited → cannot reach X in time".
"""
struct ResourceConflictCut <: SearchCut
    deep_perihelion_before_planet :: Int   # planet id
    reason :: String
end

function applies(cut::ResourceConflictCut, node::BackboneNode)
    node.resources.deep_perihelion_used &&
        cut.deep_perihelion_before_planet ∉ node.resources.planets_visited
end

"""
Pool of active cuts.
"""
struct CutPool
    cuts :: Vector{SearchCut}
end

CutPool() = CutPool(SearchCut[])

"""
Returns true if ANY cut in the pool prunes this node.
"""
function is_cut(pool::CutPool, node::BackboneNode)
    any(c -> applies(c, node), pool.cuts)
end

"""
Add a cut to the pool.
"""
function add_cut!(pool::CutPool, cut::SearchCut)
    push!(pool.cuts, cut)
end
