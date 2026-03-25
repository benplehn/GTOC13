using Test
using GTOC13
using JLD2
using LinearAlgebra
using StaticArrays

include("test_helpers.jl")

@testset "GTOC13" begin
    include("test_data_loading.jl")
    include("test_units.jl")
    include("test_mission_resources.jl")
    include("test_kepler.jl")
    include("test_frame_conventions.jl")
    include("test_elements_to_cartesian.jl")
    include("test_events.jl")
    include("test_section1_integration.jl")
    include("test_patched_conics.jl")
    include("test_score.jl")
    include("test_bounds.jl")
    include("test_branching.jl")
    include("test_sequence_feasibility.jl")
end
