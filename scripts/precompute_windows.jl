"""
Precompute encounter windows for all body pairs over the mission window.

For each body, scan [0, T_HORIZON] at coarse resolution and find time intervals
where the body is reachable from Altaira's inner system.
Results saved to data/cache/encounter_windows/.

Usage:
  julia --project scripts/precompute_windows.jl
"""

using GTOC13, JLD2

bodies = JLD2.load("data/processed/bodies.jld2", "all_bodies")

mkpath("data/cache/encounter_windows")

# TODO: for each body, call find_encounter_candidates over the full mission window
# and save the windows to disk for fast lookup during search.

println("Precompute windows: TODO — run after local solver is implemented")
