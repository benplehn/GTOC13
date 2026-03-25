@testset "Raw And Processed Data" begin
    raw_dir = normpath(joinpath(@__DIR__, "..", "data", "raw"))
    planets, asteroids, comets, all_bodies = load_all_bodies(raw_dir)

    @test length(planets) == 10
    @test length(asteroids) == 257
    @test length(comets) == 42
    @test length(all_bodies) == 310

    yandi = only(filter(body -> body.id == ID_YANDI, all_bodies))
    @test yandi.class == COMET
    @test yandi.μ == 0.0
    @test isapprox(yandi.elements.a, 596325410.852 / AU_KM; atol=1e-10)

    mktempdir() do tmpdir
        out_path = joinpath(tmpdir, "bodies.jld2")
        build_processed_bodies(raw_dir; out_path=out_path)
        loaded = load_bodies(out_path)

        @test length(loaded) == length(all_bodies)
        @test loaded[1].id == first(all_bodies).id
        @test loaded[end].id == last(all_bodies).id
    end
end
