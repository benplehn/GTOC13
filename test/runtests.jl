using Test
using GTOC13
using LinearAlgebra
using StaticArrays

@testset "GTOC13" begin
    include("test_io.jl")
    include("test_mission_resources.jl")
    include("test_kepler.jl")
    include("test_patched_conics.jl")
    include("test_score.jl")
    include("test_bounds.jl")
    include("test_branching.jl")
    include("test_sequence_feasibility.jl")
end
