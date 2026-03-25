mod_two_pi(θ::Real) = mod(float(θ), 2π)
angle_distance_el(a::Real, b::Real) = abs(mod(float(a) - float(b) + π, GTOC13.TWO_PI) - π)

function solve_kepler_spec(M::Real, e::Real; tol::Float64=1e-13, maxiter::Int=100)
    M_f = float(M)
    e_f = float(e)
    E = e_f < 0.8 ? M_f : π
    for _ in 1:maxiter
        f = E - e_f * sin(E) - M_f
        fp = 1.0 - e_f * cos(E)
        Δ = f / fp
        E -= Δ
        abs(Δ) < tol && return E
    end
    error("Spec-side Kepler solver did not converge")
end

function true_anomaly_from_mean_spec(M::Real, e::Real)
    e_f = float(e)
    E = solve_kepler_spec(mod_two_pi(M), e)
    return atan(sqrt(1.0 - e_f^2) * sin(E), cos(E) - e_f)
end

function mean_anomaly_from_true_spec(ν::Real, e::Real)
    ν_f = float(ν)
    e_f = float(e)
    E = atan(sqrt(1.0 - e_f^2) * sin(ν_f), e_f + cos(ν_f))
    return mod_two_pi(E - e_f * sin(E))
end

function analytic_elements_to_state(a::Real, e::Real, i::Real,
                                    Ω::Real, ω::Real, ν::Real,
                                    μ::Real)
    a_f = float(a)
    e_f = float(e)
    i_f = float(i)
    Ω_f = float(Ω)
    ω_f = float(ω)
    ν_f = float(ν)
    μ_f = float(μ)
    p = a_f * (1.0 - e_f^2)
    u = ω_f + ν_f
    r_norm = p / (1.0 + e_f * cos(ν_f))
    speed_scale = sqrt(μ_f / p)

    cΩ, sΩ = cos(Ω_f), sin(Ω_f)
    cu, su = cos(u), sin(u)
    cω, sω = cos(ω_f), sin(ω_f)
    ci, si = cos(i_f), sin(i_f)

    r = SVector(
        r_norm * (cΩ * cu - sΩ * su * ci),
        r_norm * (sΩ * cu + cΩ * su * ci),
        r_norm * (su * si),
    )
    v = speed_scale .* SVector(
        -cΩ * (su + e_f * sω) - sΩ * (cu + e_f * cω) * ci,
        -sΩ * (su + e_f * sω) + cΩ * (cu + e_f * cω) * ci,
        (cu + e_f * cω) * si,
    )
    return r, v
end

function state_from_true_anomaly(a::Real, e::Real, i::Real,
                                 Ω::Real, ω::Real, ν::Real,
                                 μ::Real)
    M0 = mean_anomaly_from_true_spec(ν, e)
    elements = OrbitalElements(a, e, i, mod_two_pi(Ω), mod_two_pi(ω), M0, T_LAUNCH_JD)
    return kepler_propagate(elements, T_LAUNCH_JD, μ)
end

function state_to_elements_oracle(s::CartesianState, μ::Float64; tol::Float64=1e-12)
    r = s.r
    v = s.v
    r_n = norm(r)
    v_n = norm(v)
    h = cross(r, v)
    h_n = norm(h)
    n = cross(SVector(0.0, 0.0, 1.0), h)
    n_n = norm(n)
    e_vec = ((v_n^2 - μ / r_n) .* r - dot(r, v) .* v) / μ
    e = norm(e_vec)
    a = 1.0 / (2.0 / r_n - v_n^2 / μ)
    i = acos(clamp(h[3] / h_n, -1.0, 1.0))

    Ω = if n_n < tol
        0.0
    else
        Ω_val = acos(clamp(n[1] / n_n, -1.0, 1.0))
        n[2] < 0.0 ? GTOC13.TWO_PI - Ω_val : Ω_val
    end

    ω, ν = if e < tol && n_n < tol
        0.0, mod_two_pi(atan(r[2], r[1]))
    elseif e < tol
        u = acos(clamp(dot(n, r) / (n_n * r_n), -1.0, 1.0))
        0.0, (r[3] < 0.0 ? GTOC13.TWO_PI - u : u)
    elseif n_n < tol
        ϖ = acos(clamp(e_vec[1] / e, -1.0, 1.0))
        ϖ = e_vec[2] < 0.0 ? GTOC13.TWO_PI - ϖ : ϖ
        ν_val = acos(clamp(dot(e_vec, r) / (e * r_n), -1.0, 1.0))
        ν_val = dot(r, v) < 0.0 ? GTOC13.TWO_PI - ν_val : ν_val
        ϖ, ν_val
    else
        ω_val = acos(clamp(dot(n, e_vec) / (n_n * e), -1.0, 1.0))
        ω_val = e_vec[3] < 0.0 ? GTOC13.TWO_PI - ω_val : ω_val
        ν_val = acos(clamp(dot(e_vec, r) / (e * r_n), -1.0, 1.0))
        ν_val = dot(r, v) < 0.0 ? GTOC13.TWO_PI - ν_val : ν_val
        ω_val, ν_val
    end

    M0 = if e < tol
        ν
    else
        E = 2.0 * atan(sqrt(1.0 - e) * sin(ν / 2.0), sqrt(1.0 + e) * cos(ν / 2.0))
        mod_two_pi(E - e * sin(E))
    end

    return (; a, e, i, Ω, ω, M0)
end

@testset "Elements To Cartesian" begin
    μ = MU_ALTAIRA

    @testset "Spec To Code Simple Cases" begin
        a = 1.3

        for θ in (0.0, π / 2.0, π, -π)
            r, v = state_from_true_anomaly(a, 0.0, 0.0, 0.0, 0.0, θ, μ)
            r_expected = a .* SVector(cos(θ), sin(θ), 0.0)
            v_expected = sqrt(μ / a) .* SVector(-sin(θ), cos(θ), 0.0)

            @test isapprox(r, r_expected; atol=1e-11, rtol=1e-11)
            @test isapprox(v, v_expected; atol=1e-11, rtol=1e-11)
        end

        for θ in (0.0, π / 2.0, π, -π / 3.0)
            r, v = state_from_true_anomaly(1.8, 0.25, 0.0, 0.0, 0.0, θ, μ)
            r_expected, v_expected = analytic_elements_to_state(1.8, 0.25, 0.0, 0.0, 0.0, θ, μ)

            @test isapprox(r, r_expected; atol=1e-11, rtol=1e-11)
            @test isapprox(v, v_expected; atol=1e-11, rtol=1e-11)
        end
    end

    @testset "Inclined And Retrograde Cases" begin
        cases = [
            (2.1, 0.1, π / 6.0, π / 4.0, π / 3.0, π / 2.0),
            (3.4, 0.35, π - 0.25, 0.7, 1.1, 1.3),
        ]

        for (a, e, i, Ω, ω, ν) in cases
            r, v = state_from_true_anomaly(a, e, i, Ω, ω, ν, μ)
            r_expected, v_expected = analytic_elements_to_state(a, e, i, Ω, ω, ν, μ)
            @test isapprox(r, r_expected; atol=1e-10, rtol=1e-10)
            @test isapprox(v, v_expected; atol=1e-10, rtol=1e-10)
        end
    end

    @testset "Angular Branch Cuts" begin
        ϵ = 1e-10

        r_lo, v_lo = state_from_true_anomaly(1.0, 0.0, 0.0, 0.0, 0.0, ϵ, μ)
        r_hi, v_hi = state_from_true_anomaly(1.0, 0.0, 0.0, 0.0, 0.0, GTOC13.TWO_PI - ϵ, μ)
        @test norm(r_lo - r_hi) < 1e-8
        @test norm(v_lo - v_hi) < 1e-8

        r_left, v_left = state_from_true_anomaly(2.2, 0.2, 0.0, 0.0, 0.0, π - ϵ, μ)
        r_right, v_right = state_from_true_anomaly(2.2, 0.2, 0.0, 0.0, 0.0, -π + ϵ, μ)
        @test norm(r_left - r_right) < 1e-8
        @test norm(v_left - v_right) < 1e-8
    end

    @testset "Quasi Singular Policies" begin
        cases = [
            (1.7, 1e-12, 0.4, 0.7, 0.2, 1.1),
            (1.7, 0.2, 1e-12, 0.7, 0.2, 1.1),
            (1.7, 0.2, π - 1e-12, 0.7, 0.2, 1.1),
            (4.5, 0.99, 0.6, 1.2, 0.4, 0.9),
        ]

        for (a, e, i, Ω, ω, ν) in cases
            r, v = state_from_true_anomaly(a, e, i, Ω, ω, ν, μ)
            r_expected, v_expected = analytic_elements_to_state(a, e, i, Ω, ω, ν, μ)

            @test all(isfinite, r)
            @test all(isfinite, v)
            @test isapprox(r, r_expected; atol=1e-9, rtol=1e-9)
            @test isapprox(v, v_expected; atol=1e-9, rtol=1e-9)

            state = CartesianState(T_LAUNCH_JD, r, v)
            recovered = state_to_elements(state, μ)
            @test isfinite(recovered.a)
            @test isfinite(recovered.e)
            @test isfinite(recovered.i)
            @test isfinite(recovered.Ω)
            @test isfinite(recovered.ω)
            @test isfinite(recovered.M0)
        end
    end

    @testset "Loader And Kernel Angle Convention" begin
        _, _, _, all_bodies = load_all_bodies()
        vulcan = only(filter(body -> body.id == GTOC13.ID_VULCAN, all_bodies))
        planets_path = joinpath(GTOC13.PACKAGE_ROOT, "data", "raw", GTOC13.PLANETS_FILENAME)
        fields = csv_fields(readlines(planets_path)[2])

        a = km_to_au(parse(Float64, fields[5]))
        e = parse(Float64, fields[6])
        i = deg_to_rad(parse(Float64, fields[7]))
        Ω = deg_to_rad(parse(Float64, fields[8]))
        ω = deg_to_rad(parse(Float64, fields[9]))
        M0 = deg_to_rad(parse(Float64, fields[10]))

        @test vulcan.elements.t0 == T_LAUNCH_JD
        @test isapprox(vulcan.elements.M0, M0; atol=ANGLE_ATOL, rtol=0.0)

        ν0 = true_anomaly_from_mean_spec(M0, e)
        r_expected, v_expected = analytic_elements_to_state(a, e, i, Ω, ω, ν0, μ)
        r_loaded, v_loaded = kepler_propagate(vulcan.elements, T_LAUNCH_JD, μ)

        @test isapprox(r_loaded, r_expected; atol=1e-9, rtol=1e-9)
        @test isapprox(v_loaded, v_expected; atol=1e-9, rtol=1e-9)
    end

    @testset "Cartesian To Elements Oracle And Policy" begin
        general_cases = [
            (1.9, 0.2, 0.4, 0.7, 1.1, 0.9),
            (2.4, 0.6, 0.9, 1.3, 0.2, 2.1),
        ]

        for (a, e, i, Ω, ω, ν) in general_cases
            r, v = state_from_true_anomaly(a, e, i, Ω, ω, ν, μ)
            recovered = state_to_elements(CartesianState(T_LAUNCH_JD, r, v), μ)
            oracle = state_to_elements_oracle(CartesianState(T_LAUNCH_JD, r, v), μ)

            @test isapprox(recovered.a, oracle.a; atol=1e-10, rtol=1e-10)
            @test isapprox(recovered.e, oracle.e; atol=1e-10, rtol=1e-10)
            @test isapprox(recovered.i, oracle.i; atol=1e-10, rtol=1e-10)
            @test angle_distance_el(recovered.Ω, oracle.Ω) < 1e-10
            @test angle_distance_el(recovered.ω, oracle.ω) < 1e-10
            @test angle_distance_el(recovered.M0, oracle.M0) < 1e-10
        end

        r_circ_eq, v_circ_eq = state_from_true_anomaly(1.6, 0.0, 0.0, 1.2, 2.1, 0.7, μ)
        circ_eq = state_to_elements(CartesianState(T_LAUNCH_JD, r_circ_eq, v_circ_eq), μ)
        @test isapprox(circ_eq.Ω, 0.0; atol=ANGLE_ATOL, rtol=0.0)
        @test isapprox(circ_eq.ω, 0.0; atol=ANGLE_ATOL, rtol=0.0)
        @test angle_distance_el(circ_eq.M0, mod_two_pi(1.2 + 2.1 + 0.7)) < 1e-10

        r_circ_inc, v_circ_inc = state_from_true_anomaly(1.6, 0.0, 0.4, 1.2, 2.1, 0.7, μ)
        circ_inc = state_to_elements(CartesianState(T_LAUNCH_JD, r_circ_inc, v_circ_inc), μ)
        @test angle_distance_el(circ_inc.Ω, mod_two_pi(1.2)) < 1e-10
        @test isapprox(circ_inc.ω, 0.0; atol=ANGLE_ATOL, rtol=0.0)
        @test angle_distance_el(circ_inc.M0, mod_two_pi(2.1 + 0.7)) < 1e-10

        r_eq_ell, v_eq_ell = state_from_true_anomaly(1.6, 0.3, 0.0, 1.2, 0.9, 0.4, μ)
        eq_ell = state_to_elements(CartesianState(T_LAUNCH_JD, r_eq_ell, v_eq_ell), μ)
        @test isapprox(eq_ell.Ω, 0.0; atol=ANGLE_ATOL, rtol=0.0)
        @test angle_distance_el(eq_ell.ω, mod_two_pi(1.2 + 0.9)) < 1e-10
    end
end
