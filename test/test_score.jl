@testset "Score" begin
    # Seasonal factor: first encounter must score 1
    dir = SVector(1.0, 0.0, 0.0)
    @test seasonal_factor(dir, SVector{3,Float64}[]) == 1.0

    # Exact score on empty history should be zero
    res = MissionResources(0.0, 1000.0)
    sc  = exact_score(Event[], res)
    @test sc.total_exact == 0.0
    @test sc.grand_tour_bonus == 1.0

    # Upper bound on empty node must be ≥ 0
    # (full test requires a node with bodies — placeholder)
end
