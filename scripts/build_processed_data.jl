"""
Build processed data files from raw CSV ephemerides.
Run once after downloading data from competition website.

Usage:
  julia --project scripts/build_processed_data.jl
"""

using GTOC13

out_path = build_processed_bodies("data/raw")
planets, asteroids, comets, all_bodies = load_all_bodies("data/raw")

println("Loaded $(length(planets)) planets, $(length(asteroids)) asteroids, $(length(comets)) comets")
println("Total: $(length(all_bodies)) bodies")
println("Saved to $(out_path)")
