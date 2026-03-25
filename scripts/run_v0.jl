"""
Run backbone beam search V0.

Usage:
  julia --project scripts/run_v0.jl
  julia --project scripts/run_v0.jl --width=50
"""

using GTOC13

width = 20
for arg in ARGS
    m = match(r"--width=(\d+)", arg)
    m !== nothing && (width = parse(Int, m[1]))
end

include("../src/experiments/run_backbone_v0.jl")
result = run_backbone_v0(; width=width)
println(result)
