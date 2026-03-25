using Random

specific_energy(state::CartesianState, μ::Float64) = norm(state.v)^2 / 2 - μ / norm(state.r)
specific_angular_momentum(state::CartesianState) = cross(state.r, state.v)
angle_distance(a::Real, b::Real) = abs(mod(float(a) - float(b) + π, GTOC13.TWO_PI) - π)
kepler_solver_tol(M::Float64) = 1e-12 + 8.0 * eps(max(abs(M), 1.0))
kepler_oracle_tol(M::Float64, e::Float64) =
    max(kepler_solver_tol(M), 16.0 * kepler_solver_tol(M) / max(1e-6, 1.0 - e))

kepler_residual(E::Float64, M::Float64, e::Float64) = abs(M - (E - e * sin(E)))

function solve_kepler_oracle(M::Float64, e::Float64; tol::Float64=1e-14, maxiter::Int=200)
    e == 0.0 && return M

    lo = M - e
    hi = M + e

    for _ in 1:maxiter
        mid = 0.5 * (lo + hi)
        f_mid = mid - e * sin(mid) - M
        abs(f_mid) < tol && return mid
        if f_mid > 0.0
            hi = mid
        else
            lo = mid
        end
    end

    return 0.5 * (lo + hi)
end

@testset "Kepler" begin
    μ = MU_ALTAIRA

    @testset "Kepler Equation Solver" begin
        e_cases = [0.0, 1e-12, 1e-8, 0.1, 0.5, 0.9, 0.999999]
        M_cases = [
            0.0,
            1e-12,
            -1e-12,
            1e-6,
            -1e-6,
            π - 1e-12,
            -π + 1e-12,
            π,
            -π,
            10π,
            -10π,
            1e6,
            -1e6,
        ]

        for e in e_cases, M in M_cases
            stats = GTOC13.solve_kepler_diagnostics(M, e; tol=1e-13, maxiter=50)
            E = solve_kepler(M, e; tol=1e-13, maxiter=50)
            E_oracle = solve_kepler_oracle(M, e)

            @test isfinite(E)
            @test isfinite(stats.residual)
            @test E == stats.E
            @test stats.iterations ≤ 50
            @test kepler_residual(E, M, e) ≤ kepler_solver_tol(M)
            @test isapprox(E, E_oracle; atol=kepler_oracle_tol(M, e), rtol=0.0)
        end

        rng = MersenneTwister(13)
        for _ in 1:5_000
            e = 1.0 - 10.0^(-6.0 * rand(rng))
            M = (2.0 * rand(rng) - 1.0) * 1e6

            stats = GTOC13.solve_kepler_diagnostics(M, e; tol=1e-12, maxiter=50)
            E_oracle = solve_kepler_oracle(M, e)

            @test isfinite(stats.E)
            @test stats.iterations ≤ 50
            @test kepler_residual(stats.E, M, e) ≤ kepler_solver_tol(M)
            @test isapprox(stats.E, E_oracle; atol=kepler_oracle_tol(M, e), rtol=0.0)
        end
    end

    @testset "Keplerian Coast Propagation" begin
        el = OrbitalElements(1.0, 0.12, 0.3, 0.4, 0.5, 0.6, 0.0)
        r0, v0 = kepler_propagate(el, 0.0, μ)
        s0 = CartesianState(0.0, r0, v0)

        s_same = propagate_state(s0, 0.0, μ)
        @test state_approx_equal(s_same, s0)

        s_fwd = propagate_state(s0, 15.0, μ)
        s_back = propagate_state(s_fwd, -15.0, μ)
        @test state_approx_equal(s_back, s0; atol=1e-8, rtol=1e-8)

        period = GTOC13.TWO_PI / mean_motion(el.a, μ)
        @test state_approx_equal(propagate_state(s0, period, μ),
                                 CartesianState(s0.t + period, s0.r, s0.v);
                                 atol=1e-8, rtol=1e-8)
        @test state_approx_equal(propagate_state(s0, 3period, μ),
                                 CartesianState(s0.t + 3period, s0.r, s0.v);
                                 atol=1e-8, rtol=1e-8)
        @test state_approx_equal(propagate_state(s0, -period, μ),
                                 CartesianState(s0.t - period, s0.r, s0.v);
                                 atol=1e-8, rtol=1e-8)

        energy0 = specific_energy(s0, μ)
        h0 = specific_angular_momentum(s0)
        h0_hat = h0 / norm(h0)
        el0 = state_to_elements(s0, μ)

        for dt in (-300.0, -0.1, 1e-6, 0.1, 10.0, 300.0)
            s = propagate_state(s0, dt, μ)
            h = specific_angular_momentum(s)
            h_hat = h / norm(h)

            @test isapprox(specific_energy(s, μ), energy0; atol=1e-10, rtol=1e-10)
            @test norm(h - h0) < 1e-10
            @test norm(h_hat - h0_hat) < 1e-12
            @test isapprox(dot(h0_hat, s.r), 0.0; atol=1e-10, rtol=0.0)

            el_s = state_to_elements(s, μ)
            @test isapprox(el_s.a, el0.a; atol=1e-10, rtol=1e-10)
            @test isapprox(el_s.e, el0.e; atol=1e-10, rtol=1e-10)
            @test isapprox(el_s.i, el0.i; atol=1e-10, rtol=1e-10)
        end

        peri_el = OrbitalElements(1.7, 0.4, 0.2, 0.3, 0.4, 0.0, 0.0)
        r_peri, v_peri = kepler_propagate(peri_el, 0.0, μ)
        s_peri = CartesianState(0.0, r_peri, v_peri)
        half_period = π / mean_motion(peri_el.a, μ)
        s_apo = propagate_state(s_peri, half_period, μ)
        @test isapprox(norm(s_peri.r), peri_el.a * (1.0 - peri_el.e); atol=1e-10, rtol=1e-10)
        @test isapprox(norm(s_apo.r), peri_el.a * (1.0 + peri_el.e); atol=1e-8, rtol=1e-8)

        n = mean_motion(el.a, μ)
        for t in (-2period, -17.3, 0.0, 12.0, period, 2period + 4.5)
            r_t, v_t = kepler_propagate(el, t, μ)
            state_t = CartesianState(t, r_t, v_t)
            recovered = state_to_elements(state_t, μ)
            M_expected = mod(el.M0 + n * (t - el.t0), GTOC13.TWO_PI)
            @test angle_distance(recovered.M0, M_expected) < 1e-10
        end

        edge_cases = [
            OrbitalElements(1.0, 1e-8, 0.2, 0.3, 0.4, 0.1, 0.0),
            OrbitalElements(2.5, 0.85, 0.8, 0.9, 0.7, 0.0, 0.0),
            OrbitalElements(0.3, 0.7, 0.4, 1.1, 0.2, 0.0, 0.0),
        ]

        for el_case in edge_cases
            for t in (1e-9, 1e-3, 1.0, 1e3)
                r, v = kepler_propagate(el_case, t, μ)
                @test all(isfinite, r)
                @test all(isfinite, v)
            end
        end
    end

    @testset "No Numerical Coast Propagation Path" begin
        el = OrbitalElements(1.4, 0.2, 0.25, 0.4, 0.5, 0.1, 0.0)
        r0, v0 = kepler_propagate(el, 0.0, μ)
        dep = CartesianState(0.0, r0, v0)
        arr_time = 42.0
        arr_state = propagate_state(dep, arr_time - dep.t, μ)

        GTOC13.clear_caches!()
        @test isempty(GTOC13._kepler_cache)

        r_cached, v_cached = GTOC13.cached_kepler_propagate(el, arr_time, μ)
        @test isapprox(r_cached, arr_state.r; atol=1e-10, rtol=1e-10)
        @test isapprox(v_cached, arr_state.v; atol=1e-10, rtol=1e-10)
        @test length(GTOC13._kepler_cache) == 1

        r_cached2, v_cached2 = GTOC13.cached_kepler_propagate(el, arr_time, μ)
        @test isapprox(r_cached2, r_cached; atol=0.0, rtol=0.0)
        @test isapprox(v_cached2, v_cached; atol=0.0, rtol=0.0)
        @test length(GTOC13._kepler_cache) == 1

        sol = GTOC13.solve_coast_leg(dep, arr_time, arr_state.r, μ; pos_tol=1e-12)
        @test sol.feasibility == GTOC13.FEASIBLE
        @test !isnothing(sol.leg)
        @test sol.leg.type == LEG_COAST
        @test state_approx_equal(sol.leg.state_arr, arr_state; atol=1e-10, rtol=1e-10)

        coast_source = read(joinpath(@__DIR__, "..", "src", "local_solver", "coast_leg.jl"), String)
        @test occursin("propagate_state", coast_source)
        @test !occursin("sail_acceleration", coast_source)
    end
end
