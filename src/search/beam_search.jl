"""
Beam search over the backbone mission sequence.

The beam keeps the top-W nodes by score_ub at each depth level.
Dominance pruning is applied before ranking.
"""

struct BeamSearchConfig
    width          :: Int      # beam width W
    max_depth      :: Int      # maximum number of backbone events
    t_lookahead    :: Float64  # time window for branching [days]
    use_dominance  :: Bool
    use_local_solver :: Bool   # run feasibility check before scoring
    label          :: String
end

"""
Run beam search from a root node.
Returns BeamSearchResult.
"""
function beam_search(root::BackboneNode,
                      bodies::Vector{Body},
                      μ::Float64,
                      config::BeamSearchConfig)
    t0      = time()
    beam    = BackboneNode[root]
    best    = nothing
    best_sc = 0.0
    n_expanded = 0
    n_pruned   = 0
    bound_reports = BoundReport[]

    for depth in 1:config.max_depth
        isempty(beam) && break
        next_beam = BackboneNode[]

        for node in beam
            n_expanded += 1
            candidates = generate_branches(node, bodies, μ;
                                            t_lookahead=config.t_lookahead)

            for cand in candidates
                child = expand_node(node, cand, bodies, μ, config)
                child === nothing && (n_pruned += 1; continue)

                if should_prune(child, best_sc)
                    n_pruned += 1
                    push!(bound_reports, BoundReport(child.id, depth,
                        child.score_exact, child.score_ub,
                        child.score_ub - child.score_exact,
                        0, true, "ub_below_incumbent"))
                    continue
                end

                push!(next_beam, child)
                if child.score_exact > best_sc
                    best_sc = child.score_exact
                    best    = child
                end
            end
        end

        config.use_dominance && (next_beam = remove_dominated(next_beam))

        # Rank by score_ub and truncate to beam width
        sort!(next_beam, by=n -> -n.score_ub)
        length(next_beam) > config.width && (next_beam = next_beam[1:config.width])
        beam = next_beam
    end

    elapsed = time() - t0
    mission = best === nothing ? nothing : reconstruct_mission(best)

    return BeamSearchResult(mission, best_sc, n_expanded, n_pruned,
                             bound_reports, elapsed, config.label)
end

"""
Expand a node by committing a candidate event.
Returns child node or nothing if infeasible.
"""
function expand_node(parent::BackboneNode, cand::EncounterCandidate,
                      bodies::Vector{Body}, μ::Float64,
                      config::BeamSearchConfig)
    # TODO: call local solver to get leg + feasibility
    # For V0: stub — assume feasible, use cand.score_upper as score_ub
    # (This will be replaced in Phase 4)
    return nothing   # stub: implement per phase
end

"""
Reconstruct a ScoredMission from the best terminal node.
"""
function reconstruct_mission(node::BackboneNode)
    # TODO
    return nothing
end
