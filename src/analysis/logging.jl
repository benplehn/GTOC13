"""
Structured run logging.

Log format: JSONL, one record per node expansion.
Allows post-hoc analysis without keeping the full search tree in memory.
"""

struct RunLogger
    path    :: String
    io      :: IO
    run_id  :: String
end

function RunLogger(dir::String, label::String)
    mkpath(dir)
    run_id = label * "_" * string(round(Int, time()))
    path   = joinpath(dir, run_id * ".jsonl")
    io     = open(path, "w")
    return RunLogger(path, io, run_id)
end

function log_node!(logger::RunLogger, node::BackboneNode, event::String)
    line = string(
        "{\"run_id\":", repr(logger.run_id),
        ",\"event\":", repr(event),
        ",\"node_id\":", node.id,
        ",\"depth\":", node.depth,
        ",\"score_exact\":", node.score_exact,
        ",\"score_ub\":", node.score_ub,
        ",\"t\":", node.current_state.t,
        "}"
    )
    println(logger.io, line)
    flush(logger.io)
end

function close_logger!(logger::RunLogger)
    close(logger.io)
end
