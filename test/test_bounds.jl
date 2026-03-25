@testset "Bounds admissibility" begin
    # The score upper bound must never be below the exact score.
    # Test with a trivial node (no bodies).
    launch = CartesianState(0.0, SVector(1.0,0.0,0.0), SVector(0.0,0.01,0.0))
    res    = MissionResources(0.0, 1000.0)
    root   = make_root_node(launch, res)

    ub = score_upper_bound_v0(root, Body[])
    @test ub >= root.score_exact
end
