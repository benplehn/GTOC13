@testset "Patched conics" begin
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

    planets, asteroids, comets, all_bodies = load_all_bodies()
    planet = first(planets)
    asteroid = first(asteroids)
    comet = first(comets)
    yandi = only(filter(body -> body.id == ID_YANDI, all_bodies))

    @test supports_massive_flyby(planet)
    @test !supports_massless_encounter(planet)
    @test !supports_massive_flyby(asteroid)
    @test supports_massless_encounter(asteroid)
    @test supports_massless_encounter(comet)
    @test supports_massless_encounter(yandi)
    @test !supports_massive_flyby(yandi)

    r_p_min = planet.R + GTOC13.FLYBY_ALT_MIN_RADII * planet.R
    r_p_max = planet.R + GTOC13.FLYBY_ALT_MAX_RADII * planet.R
    @test flyby_altitude_feasible(r_p_min, planet.R)
    @test flyby_altitude_feasible(r_p_max, planet.R)
    @test !flyby_altitude_feasible(r_p_min - 1e-12, planet.R)
    @test !flyby_altitude_feasible(r_p_max + 1e-12, planet.R)

    body_v = SVector(0.01, -0.02, 0.03)
    vinf_in = SVector(0.02, 0.01, -0.01)
    vinf_rot = flyby_v_out_family(vinf_in, 0.5)(0.3)
    vinf_bad = 1.1 .* vinf_in

    @test massive_vinf_magnitude_conserved(vinf_in, vinf_rot)
    @test !massive_vinf_magnitude_conserved(vinf_in, vinf_bad)
    require_massive_vinf_magnitude_conserved(vinf_in, vinf_rot)
    msg = error_message(() -> require_massive_vinf_magnitude_conserved(vinf_in, vinf_bad))
    @test occursin("conserve V∞ magnitude", msg)

    v_sc_in = body_v + vinf_in
    v_sc_out_same = body_v + vinf_in
    v_sc_out_rot = body_v + vinf_rot
    v_sc_out_scaled = body_v + 1.1 .* vinf_in

    @test massless_vinf_continuous(v_sc_in, v_sc_out_same, body_v)
    @test !massless_vinf_continuous(v_sc_in, v_sc_out_rot, body_v)
    @test !massless_vinf_continuous(v_sc_in, v_sc_out_scaled, body_v)
    require_massless_vinf_continuity(v_sc_in, v_sc_out_same, body_v)
    msg = error_message(() -> require_massless_vinf_continuity(v_sc_in, v_sc_out_rot, body_v))
    @test occursin("full V∞ continuity", msg)
end
