@testset "Mission Resources" begin
    planets, asteroids, comets, all_bodies = load_all_bodies()
    planet = first(planets)
    asteroid = first(asteroids)
    comet = first(comets)
    yandi = only(filter(body -> body.id == ID_YANDI, all_bodies))

    res0 = MissionResources(T_LAUNCH_JD, T_HORIZON_JD)

    @test !massless_scoring_allowed(res0)
    @test event_within_mission_window(res0, T_LAUNCH_JD)
    @test event_within_mission_window(res0, T_HORIZON_JD)
    @test !event_within_mission_window(res0, -eps(1.0))
    @test !event_within_mission_window(res0, T_HORIZON_JD + eps(T_HORIZON_JD))

    short_res = MissionResources(T_LAUNCH_JD, T_HORIZON_JD - 1.0)
    @test event_within_mission_window(short_res, short_res.t_horizon)
    @test !event_within_mission_window(short_res, T_HORIZON_JD)

    msg = error_message(() -> MissionResources(10.0, 9.0))
    @test occursin("Mission horizon", msg)

    msg = error_message(() -> require_within_mission_window(res0, -1.0))
    @test occursin("outside the mission window", msg)

    msg = error_message(() -> harvest_body(res0, asteroid.id))
    @test occursin("before first perihelion", msg)

    res1 = consume_perihelion(res0)
    @test massless_scoring_allowed(res1)
    @test res1.perihelion_count == 1

    res2 = visit_planet(res1, GTOC13.ID_VULCAN)
    res3 = harvest_body(res2, asteroid.id)

    @test GTOC13.ID_VULCAN ∈ res2.planets_visited
    @test asteroid.id ∈ res3.bodies_harvested
    @test GTOC13.ID_VULCAN ∉ res1.planets_visited
    @test asteroid.id ∉ res2.bodies_harvested

    deep1 = consume_deep_perihelion(res0)
    @test deep1.deep_perihelion_used
    @test deep1.first_perihelion_done

    msg = error_message(() -> consume_deep_perihelion(deep1))
    @test occursin("already consumed", msg)

    msg = error_message(() -> harvest_body(res3, planet.id))
    @test occursin("not a massless scoring target", msg)

    msg = error_message(() -> harvest_body(res3, asteroid.id))
    @test occursin("already been harvested", msg)

    state_ok = CartesianState(10.0, SVector(1.0, 0.0, 0.0), SVector(0.0, 0.01, 0.0))
    state_bad = CartesianState(T_HORIZON_JD + 10.0, SVector(1.0, 0.0, 0.0), SVector(0.0, 0.01, 0.0))
    ev_ok = perihelion_event(state_ok, res0)
    ev_bad = Event(-1, EVT_PERIHELION, state_bad.t, state_bad, nothing, 0.0, res0)

    @test sequence_within_mission_window(res0, [ev_ok])
    @test !sequence_within_mission_window(res0, [ev_ok, ev_bad])

    msg = error_message(() -> require_sequence_within_mission_window(res0, [ev_ok, ev_bad]))
    @test occursin("outside the mission window", msg)

    @test classify_perihelion_radius(R_NORMAL_PERIHELION, res0) == :nominal
    @test classify_perihelion_radius(0.049999, res0) == :deep
    @test classify_perihelion_radius(0.051, res0) == :nominal
    @test classify_perihelion_radius(R_DEEP_PERIHELION, res0) == :deep
    @test classify_perihelion_radius(R_DEEP_PERIHELION - 2.0 * PERIHELION_CHECKER_TOL_AU, res0) == :invalid

    @test classify_perihelion_radius(R_NORMAL_PERIHELION - 0.5 * PERIHELION_CHECKER_TOL_AU, res0) == :nominal
    @test classify_perihelion_radius(R_NORMAL_PERIHELION - 1.5 * PERIHELION_CHECKER_TOL_AU, res0) == :deep
    @test classify_perihelion_radius(R_DEEP_PERIHELION - 0.5 * PERIHELION_CHECKER_TOL_AU, res0) == :deep
    @test classify_perihelion_radius(R_DEEP_PERIHELION - 1.5 * PERIHELION_CHECKER_TOL_AU, res0) == :invalid

    @test perihelion_radius_allowed(0.04, res0)
    @test !perihelion_radius_allowed(0.009, res0)
    @test require_perihelion_radius_allowed(0.04, res0) == :deep
    @test require_perihelion_radius_allowed(0.01, res0) == :deep

    msg = error_message(() -> require_perihelion_radius_allowed(0.009, res0))
    @test occursin("absolute minimum", msg)

    msg = error_message(() -> require_perihelion_radius_allowed(0.04, deep1))
    @test occursin("Deep perihelion slot has already been consumed", msg)

    deep_first = consume_deep_perihelion(res0)
    deep_middle = consume_deep_perihelion(consume_perihelion(res0))
    deep_last = consume_deep_perihelion(consume_perihelion(consume_perihelion(res0)))
    @test deep_first.deep_perihelion_used && deep_first.perihelion_count == 1
    @test deep_middle.deep_perihelion_used && deep_middle.perihelion_count == 2
    @test deep_last.deep_perihelion_used && deep_last.perihelion_count == 3

    encounter_state = CartesianState(20.0, SVector(1.0, 0.0, 0.0), SVector(0.0, 0.01, 0.0))
    asteroid_ev = massless_encounter_event(asteroid, encounter_state, res0)
    comet_ev = massless_encounter_event(comet, encounter_state, res0)
    yandi_ev = massless_encounter_event(yandi, encounter_state, res0)

    @test exact_score([asteroid_ev], res0).total_exact == 0.0
    @test exact_score([comet_ev], res0).total_exact == 0.0
    @test exact_score([yandi_ev], res0).total_exact == 0.0

    @test exact_score([asteroid_ev], res1).total_exact > 0.0
    @test exact_score([comet_ev], res1).total_exact > 0.0
    @test exact_score([yandi_ev], res1).total_exact > 0.0

    msg = error_message(() -> harvest_body(res0, comet.id))
    @test occursin("before first perihelion", msg)

    msg = error_message(() -> harvest_body(res0, yandi.id))
    @test occursin("before first perihelion", msg)

    @test harvest_body(res1, comet.id).bodies_harvested == Set([comet.id])
    @test harvest_body(res1, yandi.id).bodies_harvested == Set([yandi.id])

    msg = error_message(() -> body_weight(999999))
    @test occursin("Unknown body_id", msg)
end
