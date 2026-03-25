"""
Dominance pruning: discard nodes that cannot beat the current best.

Node A dominates node B if:
  - A.score_exact >= B.score_exact
  - A.score_ub    >= B.score_ub
  - A.resources is "at least as good" as B.resources
  - A.depth <= B.depth  (optional: same-depth dominance is stricter)

Start simple (score_ub dominance only) and tighten as needed.
"""

"""
Returns true if `a` dominates `b` and `b` should be pruned.
"""
function dominates(a::BackboneNode, b::BackboneNode)
    a.score_ub  >= b.score_ub   || return false
    a.score_exact >= b.score_exact || return false
    # Resources: a must have consumed no more critical resources than b
    # (conservative: only check deep perihelion and planets)
    a.resources.deep_perihelion_used && !b.resources.deep_perihelion_used && return false
    return true
end

"""
Filter a list of nodes, removing dominated ones.
O(n²) — acceptable for beam widths < 1000.
"""
function remove_dominated(nodes::Vector{BackboneNode})
    keep = trues(length(nodes))
    for i in eachindex(nodes)
        keep[i] || continue
        for j in eachindex(nodes)
            i == j && continue
            keep[j] || continue
            if dominates(nodes[i], nodes[j])
                keep[j] = false
            end
        end
    end
    return nodes[keep]
end
