@testset "Events And Nodes" begin
    planets, asteroids, _, _ = load_all_bodies()
    planet = first(planets)
    asteroid = first(asteroids)
    bodies_by_id = Dict(body.id => body for body in vcat(planets, asteroids))

    root_resources = MissionResources(T_LAUNCH_JD, T_HORIZON_JD)
    state = CartesianState(10.0, SVector(1.0, 0.0, 0.0), SVector(0.0, 0.01, 0.0))
    root = make_root_node(state, root_resources)

    @test root.depth == 0
    @test isempty(root.history)
    @test root.score_exact == 0.0
    @test root.parent_id == 0
    @test !root.is_terminal
    @test occursin("Node(", sprint(show, root))
    @test deepcopy(root).id == root.id

    launch_ev = launch_event(state, root_resources)
    peri_ev = perihelion_event(state, root_resources)
    flyby_ev = massive_flyby_event(planet, state, visit_planet(root_resources, planet.id))
    massless_ev = massless_encounter_event(asteroid, state, consume_perihelion(root_resources))
    end_ev = end_event(state, root_resources)

    @test launch_ev.event_type == EVT_LAUNCH
    @test peri_ev.event_type == EVT_PERIHELION
    @test flyby_ev.event_type == EVT_MASSIVE_FLYBY
    @test flyby_ev.body_id == planet.id
    @test massless_ev.event_type == EVT_MASSLESS_ENCOUNTER
    @test massless_ev.body_id == asteroid.id
    @test end_ev.event_type == EVT_END

    @test isfinite(launch_ev.t)
    @test isfinite(peri_ev.t)
    @test isfinite(flyby_ev.t)
    @test isfinite(massless_ev.t)
    @test launch_ev.body_id == -1
    @test end_ev.body_id == -1
    @test flyby_ev.state == state
    @test massless_ev.state == state

    msg = error_message(() -> massive_flyby_event(asteroid, state, root_resources))
    @test occursin("cannot generate a massive flyby", msg)

    msg = error_message(() -> massless_encounter_event(planet, state, root_resources))
    @test occursin("cannot generate a massless encounter", msg)

    late_state = CartesianState(T_HORIZON_JD + 1.0, state.r, state.v)
    msg = error_message(() -> perihelion_event(late_state, root_resources))
    @test occursin("outside the mission window", msg)

    events_same_time = [launch_ev, peri_ev, flyby_ev]
    @test events_nondecreasing(events_same_time)
    require_nondecreasing_event_times(events_same_time)

    earlier = CartesianState(9.0, state.r, state.v)
    out_of_order = [perihelion_event(state, root_resources), launch_event(earlier, root_resources)]
    @test !events_nondecreasing(out_of_order)
    msg = error_message(() -> require_nondecreasing_event_times(out_of_order))
    @test occursin("nondecreasing", msg)

    body_r_close = state.r + SVector(0.5 * FLYBY_POSITION_TOL_AU, 0.0, 0.0)
    body_r_far = state.r + SVector(1.5 * FLYBY_POSITION_TOL_AU, 0.0, 0.0)
    @test same_position_at_flyby(state, state.r)
    @test same_position_at_flyby(state, body_r_close)
    @test !same_position_at_flyby(state, body_r_far)
    msg = error_message(() -> require_same_position_at_flyby(state, body_r_far))
    @test occursin("position mismatch", msg)

    Δt_min = minimum_reflyby_separation(planet)
    t0 = 40.0
    same_body_a = massive_flyby_event(planet, CartesianState(t0, state.r, state.v), visit_planet(root_resources, planet.id))
    same_body_b = massive_flyby_event(planet, CartesianState(t0 + Δt_min, state.r, state.v), visit_planet(root_resources, planet.id))
    same_body_c = massive_flyby_event(planet, CartesianState(t0 + Δt_min - 1e-9, state.r, state.v), visit_planet(root_resources, planet.id))
    other_body = massless_encounter_event(asteroid, CartesianState(t0 + 1.0, state.r, state.v), consume_perihelion(root_resources))

    @test successive_same_body_flybys(same_body_a, same_body_b)
    @test !successive_same_body_flybys(same_body_a, other_body)
    require_adjacent_reflyby_spacing([same_body_a, same_body_b], bodies_by_id)
    msg = error_message(() -> require_adjacent_reflyby_spacing([same_body_a, same_body_c], bodies_by_id))
    @test occursin("must be separated", msg)
    require_adjacent_reflyby_spacing([same_body_a, other_body, same_body_c], bodies_by_id)

    mktempdir() do tmpdir
        path = joinpath(tmpdir, "roundtrip.jld2")
        jldsave(path; body=planet, event=flyby_ev, node=root)

        body_rt = JLD2.load(path, "body")
        event_rt = JLD2.load(path, "event")
        node_rt = JLD2.load(path, "node")

        @test body_rt.id == planet.id
        @test event_rt.body_id == flyby_ev.body_id
        @test event_rt.event_type == flyby_ev.event_type
        @test node_rt.id == root.id
        @test node_rt.depth == root.depth
    end

    mktempdir() do tmpdir
        logger = RunLogger(tmpdir, "section1_events")
        GTOC13.log_node!(logger, root, "root_created")
        GTOC13.close_logger!(logger)

        content = strip(read(logger.path, String))
        @test occursin("\"event\":\"root_created\"", content)
        @test occursin("\"node_id\":$(root.id)", content)
    end
end
