@testset "Section 1 Integration" begin
    planets, asteroids, _, all_bodies = load_all_bodies()
    planet = first(planets)
    asteroid = first(asteroids)

    @test GTOC13.SC_INITIAL_X == -200.0
    @test GTOC13.SC_INITIAL_VY == 0.0
    @test GTOC13.SC_INITIAL_VZ == 0.0

    launch_r, launch_v = kepler_propagate(planet.elements, T_LAUNCH_JD, MU_ALTAIRA)
    launch_state = CartesianState(T_LAUNCH_JD, launch_r, launch_v)
    root_resources = MissionResources(T_LAUNCH_JD, T_HORIZON_JD)
    root = make_root_node(launch_state, root_resources)

    @test root.current_state.t == T_LAUNCH_JD
    @test event_within_mission_window(root_resources, root.current_state.t)

    coast_state = propagate_state(launch_state, 30.0, MU_ALTAIRA)
    @test coast_state.t == 30.0

    @test classify_perihelion_radius(0.08, root_resources) == :nominal
    @test classify_perihelion_radius(0.04, root_resources) == :deep
    @test !perihelion_radius_allowed(0.009, root_resources)
    @test require_perihelion_radius_allowed(0.04, root_resources) == :deep

    peri_resources = consume_perihelion(root_resources)
    peri_state = CartesianState(coast_state.t, SVector(0.04, 0.0, 0.0), coast_state.v)
    peri_event = perihelion_event(peri_state, peri_resources)
    @test peri_event.event_type == EVT_PERIHELION
    @test massless_scoring_allowed(peri_resources)

    deep_used = consume_deep_perihelion(root_resources)
    msg = error_message(() -> require_perihelion_radius_allowed(0.04, deep_used))
    @test occursin("Deep perihelion slot has already been consumed", msg)

    msg = error_message(() -> require_perihelion_radius_allowed(0.009, root_resources))
    @test occursin("absolute minimum", msg)

    flyby_t = 80.0
    flyby_r, flyby_v = kepler_propagate(planet.elements, flyby_t, MU_ALTAIRA)
    flyby_state = CartesianState(flyby_t, flyby_r, flyby_v)
    flyby_resources = visit_planet(peri_resources, planet.id)
    flyby_event = massive_flyby_event(planet, flyby_state, flyby_resources)
    @test flyby_event.body_id == planet.id

    encounter_t = 120.0
    encounter_r, encounter_v = kepler_propagate(asteroid.elements, encounter_t, MU_ALTAIRA)
    encounter_state = CartesianState(encounter_t, encounter_r, encounter_v)

    msg = error_message(() -> harvest_body(root_resources, asteroid.id))
    @test occursin("before first perihelion", msg)

    encounter_resources = harvest_body(flyby_resources, asteroid.id)
    encounter_event = massless_encounter_event(asteroid, encounter_state, encounter_resources)
    @test encounter_event.body_id == asteroid.id

    @test exact_score([encounter_event], root_resources).total_exact == 0.0
    @test exact_score([encounter_event], encounter_resources).total_exact > 0.0

    Δt_min = minimum_reflyby_separation(planet)
    @test !flyby_revisit_allowed(planet, 0.0, 0.25 * orbital_period(planet))
    @test flyby_revisit_allowed(planet, 0.0, Δt_min + 1e-6)
    require_flyby_revisit_spacing(planet, 0.0, Δt_min + 1e-6)

    msg = error_message(() -> require_flyby_revisit_spacing(planet, 0.0, 0.25 * orbital_period(planet)))
    @test occursin("must be separated", msg)

    r_test = SVector(1.0, 0.0, 0.0)
    v_test = SVector(0.0, 1.0, 0.0)
    @test sail_cone_angle_in_domain(0.0)
    @test sail_cone_angle_in_domain(π / 2)
    @test !sail_cone_angle_in_domain(-1e-3)
    @test !sail_cone_angle_in_domain(π / 2 + 1e-3)

    u0 = GTOC13.sail_normal_from_angles(r_test, v_test, 0.0, 0.0)
    u90 = GTOC13.sail_normal_from_angles(r_test, v_test, π / 2, 0.0)
    @test isapprox(u0, SVector(-1.0, 0.0, 0.0); atol=VECTOR_ATOL, rtol=0.0)
    @test isapprox(dot(u90, -r_test / norm(r_test)), 0.0; atol=ANGLE_ATOL, rtol=0.0)

    msg = error_message(() -> GTOC13.sail_normal_from_angles(r_test, v_test, -0.1, 0.0))
    @test occursin("outside the allowed domain", msg)

    msg = error_message(() -> GTOC13.sail_normal_from_angles(r_test, v_test, π / 2 + 0.1, 0.0))
    @test occursin("outside the allowed domain", msg)

    history = [peri_event, flyby_event, encounter_event]
    @test sequence_within_mission_window(root_resources, history)

    child = extend_node(root, peri_event, peri_resources, exact_score(Event[], peri_resources),
                        score_upper_bound_v0(root, all_bodies))
    @test child.depth == 1
    @test length(child.history) == 1
    @test child.history[1].event_type == EVT_PERIHELION
end
