"""
Pretty-printing for types.
"""

function Base.show(io::IO, b::Body)
    print(io, "Body($(b.name), $(b.class), a=$(round(b.elements.a, digits=3)) AU)")
end

function Base.show(io::IO, n::BackboneNode)
    print(io, "Node(id=$(n.id), depth=$(n.depth), score=$(round(n.score_exact,digits=4)), ub=$(round(n.score_ub,digits=4)))")
end

function Base.show(io::IO, r::BeamSearchResult)
    print(io, "BeamResult(score=$(round(r.best_score,digits=4)), nodes=$(r.n_nodes_expanded), t=$(round(r.elapsed_seconds,digits=1))s, config=$(r.config_label))")
end
