@testset "Kepler propagation" begin
    μ = MU_ALTAIRA
    el = OrbitalElements(1.0, 0.0167, 0.0, 0.0, 0.0, 0.0, 0.0)

    # Propagate one full period → should return to same position
    T = 2π * sqrt(el.a^3 / μ)
    r0, v0 = kepler_propagate(el, 0.0, μ)
    r1, v1 = kepler_propagate(el, T, μ)

    @test norm(r1 - r0) < 1e-8
    @test norm(v1 - v0) < 1e-8

    # Round-trip: state → elements → state
    s0 = CartesianState(0.0, r0, v0)
    el2 = state_to_elements(s0, μ)
    @test abs(el2.a - el.a) < 1e-10
    @test abs(el2.e - el.e) < 1e-10
end
