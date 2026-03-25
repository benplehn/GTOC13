"""
Save mission results and run logs.
"""

"""
Save a ScoredMission to disk (JLD2 + human-readable summary).
"""
function save_mission(mission::ScoredMission, dir::String, label::String)
    mkpath(dir)
    stem = joinpath(dir, label)
    jldsave(stem * ".jld2"; mission=mission)

    open(stem * ".txt", "w") do io
        println(io, "label=$(mission.label)")
        println(io, "events=$(length(mission.events))")
        println(io, "score=$(mission.score.total_exact)")
        println(io, "planets_visited=$(collect(sort(mission.resources.planets_visited)))")
        println(io, "bodies_harvested=$(collect(sort(mission.resources.bodies_harvested)))")
    end

    return stem
end

"""
Save a BeamSearchResult log.
"""
function save_run_log(result::BeamSearchResult, dir::String)
    mkpath(dir)
    stem = joinpath(dir, result.config_label)
    jldsave(stem * ".jld2"; result=result)

    open(stem * "_summary.txt", "w") do io
        println(io, "config=$(result.config_label)")
        println(io, "best_score=$(result.best_score)")
        println(io, "n_nodes_expanded=$(result.n_nodes_expanded)")
        println(io, "n_nodes_pruned=$(result.n_nodes_pruned)")
        println(io, "elapsed_seconds=$(result.elapsed_seconds)")
        println(io, "n_bound_reports=$(length(result.bound_reports))")
    end

    return stem
end
