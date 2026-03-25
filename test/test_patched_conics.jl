@testset "Patched conics" begin
    using GTOC13

    # Turn angle should increase with μ_body and decrease with v_inf
    μ_body = 1e-7   # small planet
    r_p    = 1e-4   # close periapsis
    v_inf  = 0.01

    δ = flyby_turn_angle(v_inf, r_p, μ_body)
    @test 0 < δ ≤ π

    # Higher μ → larger turn
    δ2 = flyby_turn_angle(v_inf, r_p, 10 * μ_body)
    @test δ2 > δ

    # Higher v_inf → smaller turn
    δ3 = flyby_turn_angle(10 * v_inf, r_p, μ_body)
    @test δ3 < δ
end
