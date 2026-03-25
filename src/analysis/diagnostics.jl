"""
Diagnostic tools for understanding search behavior.
"""

"""
Print a human-readable summary of a search run.
"""
function print_run_summary(result::BeamSearchResult)
    m = compute_metrics(result)
    println("=== Run: $(m.config_label) ===")
    println("  Best score      : $(m.best_score)")
    println("  Nodes expanded  : $(m.n_nodes_expanded)")
    println("  Nodes pruned    : $(m.n_nodes_pruned)")
    println("  Prune rate      : $(round(100*m.prune_rate, digits=1))%")
    println("  Mean bound gap  : $(round(m.mean_bound_gap, digits=4))")
    println("  Max depth       : $(m.max_depth_reached)")
    println("  Elapsed         : $(round(m.elapsed_s, digits=2))s")
end

"""
Report the bottleneck: where does the search spend most time / lose most score?
"""
function bottleneck_report(results::Vector{BeamSearchResult})
    # TODO: aggregate bound_reports across runs, identify worst-gap nodes
end
