"""
Search algorithm types: nodes, labels, reports.

Design constraint: search types must NOT import local_solver or relaxations.
They only hold data. Logic lives in search/*.jl.
"""

"""
A node in the search tree.

Immutable by design: branching creates new nodes, never mutates.
This makes dominance checking, caching, and parallelism straightforward.
"""
struct BackboneNode
    # Identity
    id     :: Int        # unique node id (assigned at creation)
    depth  :: Int        # number of events committed so far

    # Current mission state
    current_state  :: CartesianState
    resources      :: MissionResources
    score_state    :: ScoreState

    # History of committed events (backbone only; harvesting is separate)
    history :: Vector{Event}

    # Bounds
    score_exact    :: Float64   # exact score of history so far
    score_ub       :: Float64   # upper bound on total achievable score from here

    # Search metadata
    parent_id :: Int    # 0 for root
    is_terminal :: Bool
end

"""
A beam label: what the beam search tracks at each frontier position.
Lighter than a full node; the full node is reconstructed on demand.
"""
struct BeamLabel
    node_id   :: Int
    score_ub  :: Float64   # for ranking
    score_lb  :: Float64   # best known lower bound (from any descendant)
    depth     :: Int
end

"""
A harvesting node: built on top of a fixed backbone, adds small bodies.
Separate from backbone nodes to enable the backbone/harvesting decomposition.
"""
struct HarvestNode
    backbone_node_id :: Int
    # Additional events added by greedy / local harvesting search
    harvest_events :: Vector{Event}
    resources      :: MissionResources
    score_state    :: ScoreState
    score_ub       :: Float64
end

"""
Report from a single search run.
"""
struct BoundReport
    node_id     :: Int
    depth       :: Int
    score_exact :: Float64
    score_ub    :: Float64
    gap         :: Float64   # score_ub - score_exact
    n_children  :: Int
    pruned      :: Bool
    prune_reason :: String
end

"""
Summary of a full beam search run.
"""
struct BeamSearchResult
    best_mission  :: Union{ScoredMission, Nothing}
    best_score    :: Float64
    n_nodes_expanded :: Int
    n_nodes_pruned   :: Int
    bound_reports    :: Vector{BoundReport}
    elapsed_seconds  :: Float64
    config_label     :: String
end
