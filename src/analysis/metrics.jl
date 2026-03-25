"""
Mission quality metrics for analysis and ablation.
"""

struct RunMetrics
    best_score         :: Float64
    n_nodes_expanded   :: Int
    n_nodes_pruned     :: Int
    prune_rate         :: Float64
    mean_bound_gap     :: Float64
    max_depth_reached  :: Int
    elapsed_s          :: Float64
    config_label       :: String
end

function compute_metrics(result::BeamSearchResult)
    prune_rate = result.n_nodes_pruned /
                 max(1, result.n_nodes_expanded + result.n_nodes_pruned)
    gaps = [r.gap for r in result.bound_reports]
    mean_gap = isempty(gaps) ? NaN : sum(gaps) / length(gaps)
    max_depth = isempty(result.bound_reports) ? 0 :
                maximum(r.depth for r in result.bound_reports)
    return RunMetrics(result.best_score, result.n_nodes_expanded,
                      result.n_nodes_pruned, prune_rate, mean_gap,
                      max_depth, result.elapsed_seconds, result.config_label)
end
