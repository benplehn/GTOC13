@testset "Mission Resources" begin
    res0 = MissionResources(0.0, 1000.0)
    res1 = consume_perihelion(res0)
    res2 = visit_planet(res1, 1)
    res3 = harvest_body(res2, 1001)

    @test !res0.first_perihelion_done
    @test res1.first_perihelion_done
    @test res1.perihelion_count == 1

    @test 1 ∉ res1.planets_visited
    @test 1 ∈ res2.planets_visited

    @test 1001 ∉ res2.bodies_harvested
    @test 1001 ∈ res3.bodies_harvested

    # No aliasing between states.
    @test isempty(res0.planets_visited)
    @test isempty(res0.bodies_harvested)
    @test isempty(res1.planets_visited)
    @test isempty(res1.bodies_harvested)
end
