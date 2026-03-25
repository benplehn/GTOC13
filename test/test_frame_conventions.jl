function in_plane_unit_direction(pole::SVector{3,Float64})
    seed = SVector(1.0, -2.0, 0.5)
    projected = seed - dot(seed, pole) * pole
    return projected / norm(projected)
end

@testset "Frame Conventions" begin
    _, _, _, all_bodies = load_all_bodies()
    vulcan = only(filter(body -> body.id == GTOC13.ID_VULCAN, all_bodies))

    r_vulcan, v_vulcan = kepler_propagate(vulcan.elements, T_LAUNCH_JD, MU_ALTAIRA)
    vulcan_state = CartesianState(T_LAUNCH_JD, r_vulcan, v_vulcan)
    pole = vulcan_orbital_pole(vulcan_state)
    x_dir = in_plane_unit_direction(pole)

    @testset "GTOC13 Frame Axes" begin
        frame = gtoc13_reference_frame(vulcan_state, x_dir)

        @test isapprox(norm(frame.x̂), 1.0; atol=VECTOR_ATOL, rtol=0.0)
        @test isapprox(norm(frame.ŷ), 1.0; atol=VECTOR_ATOL, rtol=0.0)
        @test isapprox(norm(frame.ẑ), 1.0; atol=VECTOR_ATOL, rtol=0.0)

        @test isapprox(dot(frame.x̂, frame.ŷ), 0.0; atol=ANGLE_ATOL, rtol=0.0)
        @test isapprox(dot(frame.x̂, frame.ẑ), 0.0; atol=ANGLE_ATOL, rtol=0.0)
        @test isapprox(dot(frame.ŷ, frame.ẑ), 0.0; atol=ANGLE_ATOL, rtol=0.0)

        @test isapprox(frame.ŷ, cross(frame.ẑ, frame.x̂); atol=VECTOR_ATOL, rtol=0.0)
        @test isapprox(cross(frame.x̂, frame.ŷ), frame.ẑ; atol=VECTOR_ATOL, rtol=0.0)

        frame_from_body = gtoc13_reference_frame(vulcan, x_dir; t=T_LAUNCH_JD)
        @test isapprox(frame_from_body.x̂, frame.x̂; atol=VECTOR_ATOL, rtol=0.0)
        @test isapprox(frame_from_body.ŷ, frame.ŷ; atol=VECTOR_ATOL, rtol=0.0)
        @test isapprox(frame_from_body.ẑ, frame.ẑ; atol=VECTOR_ATOL, rtol=0.0)

        other_planet = first(filter(body -> body.id != GTOC13.ID_VULCAN && body.class == PLANET, all_bodies))
        msg = error_message(() -> gtoc13_reference_frame(other_planet, x_dir; t=T_LAUNCH_JD))
        @test occursin("anchored on Vulcan", msg)

        bad_direction = (x_dir + 0.2 * pole) / norm(x_dir + 0.2 * pole)
        msg = error_message(() -> gtoc13_reference_frame(vulcan_state, bad_direction))
        @test occursin("Vulcan ecliptic plane", msg)
    end

    @testset "Initial Spacecraft State" begin
        @test initial_epoch_days(0.0) == 0.0
        @test initial_epoch_days(GTOC13.T_MISSION_YEARS) == GTOC13.T_HORIZON_DAYS

        state0 = initial_spacecraft_state(0.0; y0_au=1.25, z0_au=-0.75, vx_auday=0.0123)
        @test state0.t == 0.0
        @test state0.r == SVector(GTOC13.SC_INITIAL_X, 1.25, -0.75)
        @test state0.v == SVector(0.0123, GTOC13.SC_INITIAL_VY, GTOC13.SC_INITIAL_VZ)

        state_horizon = initial_spacecraft_state(GTOC13.T_MISSION_YEARS; y0_au=-3.0, z0_au=2.0, vx_auday=-0.01)
        @test state_horizon.t == GTOC13.T_HORIZON_DAYS
        @test state_horizon.r == SVector(GTOC13.SC_INITIAL_X, -3.0, 2.0)
        @test state_horizon.v == SVector(-0.01, GTOC13.SC_INITIAL_VY, GTOC13.SC_INITIAL_VZ)

        msg = error_message(() -> initial_epoch_days(-1e-12))
        @test occursin("must lie in [0, 200.0]", msg)

        msg = error_message(() -> initial_spacecraft_state(GTOC13.T_MISSION_YEARS + 1e-12))
        @test occursin("must lie in [0, 200.0]", msg)
    end

    @testset "Epoch And Angle Conventions" begin
        planets_path = joinpath(GTOC13.PACKAGE_ROOT, "data", "raw", GTOC13.PLANETS_FILENAME)
        fields = csv_fields(readlines(planets_path)[2])

        @test parse(Int, fields[1]) == GTOC13.ID_VULCAN
        @test vulcan.elements.t0 == T_LAUNCH_JD
        @test isapprox(vulcan.elements.i, deg_to_rad(parse(Float64, fields[7])); atol=ANGLE_ATOL, rtol=0.0)
        @test isapprox(vulcan.elements.Ω, deg_to_rad(parse(Float64, fields[8])); atol=ANGLE_ATOL, rtol=0.0)
        @test isapprox(vulcan.elements.ω, deg_to_rad(parse(Float64, fields[9])); atol=ANGLE_ATOL, rtol=0.0)
        @test isapprox(vulcan.elements.M0, deg_to_rad(parse(Float64, fields[10])); atol=ANGLE_ATOL, rtol=0.0)

        r_epoch, v_epoch = kepler_propagate(vulcan.elements, T_LAUNCH_JD, MU_ALTAIRA)
        r_ref, v_ref = kepler_propagate(vulcan.elements, vulcan.elements.t0, MU_ALTAIRA)
        @test isapprox(r_epoch, r_ref; atol=VECTOR_ATOL, rtol=0.0)
        @test isapprox(v_epoch, v_ref; atol=VECTOR_ATOL, rtol=0.0)
    end
end
