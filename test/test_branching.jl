@testset "Branching" begin
    launch = CartesianState(0.0, SVector(1.0,0.0,0.0), SVector(0.0,0.01,0.0))
    res    = MissionResources(0.0, 1000.0)
    root   = make_root_node(launch, res)

    # With no bodies, branching should return empty or only perihelion branch
    cands = generate_branches(root, Body[], MU_ALTAIRA)
    # Should not crash; perihelion branch expected if deep not yet used
    @test cands isa Vector{EncounterCandidate}
end
