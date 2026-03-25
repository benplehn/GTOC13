"""
Experiment: backbone beam search V0.

Runs beam search with a minimal branching set (planets + perihelion only),
no local solver, crude upper bound.

Purpose: validate search plumbing, measure node expansion rates,
identify obvious prune opportunities before adding complexity.
"""

include("../../src/GTOC13.jl")
using .GTOC13

function run_backbone_v0(; width=20)
    bodies = load_bodies("data/processed/bodies.jld2")
    launch_state = CartesianState(T_LAUNCH_JD,
                                   SVector(1.0, 0.0, 0.0),   # TODO: real launch
                                   SVector(0.0, 0.01, 0.0))
    resources = MissionResources(T_LAUNCH_JD, T_HORIZON_JD)
    root = make_root_node(launch_state, resources)

    config = BeamSearchConfig(width, 10, 365.0, true, false, "backbone_v0_w$(width)")
    result = beam_search(root, bodies, MU_ALTAIRA, config)

    print_run_summary(result)
    save_run_log(result, "results/runs")
    return result
end
