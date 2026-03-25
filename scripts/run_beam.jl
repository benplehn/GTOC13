"""
Run beam search with a config file.

Usage:
  julia --project scripts/run_beam.jl configs/beam_small.toml
"""

using GTOC13, TOML

config_path = length(ARGS) > 0 ? ARGS[1] : "configs/beam_small.toml"
cfg = TOML.parsefile(config_path)

# TODO: wire config dict to BeamSearchConfig and run
println("Config loaded: $(cfg["output"]["label"])")
println("Beam width: $(cfg["search"]["beam_width"])")
