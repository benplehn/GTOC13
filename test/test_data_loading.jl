raw_dir() = joinpath(GTOC13.PACKAGE_ROOT, "data", "raw")

function write_lines(path::String, lines::Vector{String})
    open(path, "w") do io
        for line in lines
            println(io, line)
        end
    end
end

function with_temp_raw_copy(f::Function)
    mktempdir() do tmpdir
        for filename in (GTOC13.PLANETS_FILENAME, GTOC13.ASTEROIDS_FILENAME, GTOC13.COMETS_FILENAME)
            cp(joinpath(raw_dir(), filename), joinpath(tmpdir, filename))
        end
        return f(tmpdir)
    end
end

@testset "Data Loading" begin
    @testset "Raw File Integrity" begin
        expected = Dict(
            GTOC13.PLANETS_FILENAME => GTOC13.PLANETS_HEADER_FIELDS,
            GTOC13.ASTEROIDS_FILENAME => GTOC13.ASTEROIDS_HEADER_FIELDS,
            GTOC13.COMETS_FILENAME => GTOC13.COMETS_HEADER_FIELDS,
        )
        numeric_column_indices = Dict(
            GTOC13.PLANETS_FILENAME => [1, 3, 4, 5, 6, 7, 8, 9, 10, 11],
            GTOC13.ASTEROIDS_FILENAME => collect(1:8),
            GTOC13.COMETS_FILENAME => collect(1:8),
        )

        for (filename, header_expected) in expected
            path = joinpath(raw_dir(), filename)
            @test isfile(path)

            lines = readlines(path)
            @test !isempty(lines)
            @test csv_fields(lines[1]) == header_expected

            expected_width = length(header_expected)
            ids = Int[]

            for line in lines[2:end]
                @test !isempty(strip(normalize_csv_line(line)))
                fields = csv_fields(line)
                @test length(fields) == expected_width

                push!(ids, parse(Int, fields[1]))
                for idx in numeric_column_indices[filename]
                    value = parse(Float64, fields[idx])
                    @test isfinite(value)
                end
            end

            @test length(ids) == length(unique(ids))
        end
    end

    @testset "Catalogue Counts And Categories" begin
        planets, asteroids, comets, all_bodies = load_all_bodies()
        ids = [body.id for body in all_bodies]

        @test length(planets) == 10
        @test length(asteroids) == 257
        @test length(comets) == 42
        @test length(all_bodies) == 310
        @test length(unique(ids)) == length(ids)

        @test all(body -> 1 ≤ body.id ≤ 10, planets)
        @test [body.id for body in asteroids] == collect(GTOC13.ASTEROID_ID_MIN:GTOC13.ASTEROID_ID_MAX)
        @test [body.id for body in comets] == collect(GTOC13.COMET_ID_MIN:GTOC13.COMET_ID_MAX)

        @test is_planet(10)
        @test !is_planet(11)
        @test !is_massless(999)
        @test is_massless(1000)
        @test is_massless(1001)
        @test is_massless(1257)
        @test !is_massless(1258)
        @test !is_massless(2000)
        @test is_massless(2001)
        @test is_massless(2042)
        @test !is_massless(2043)

        @test all(has_ephemeris_source, all_bodies)
        @test all(supports_massive_flyby, planets)
        @test all(!supports_massive_flyby(body) for body in asteroids)
        @test all(supports_massless_encounter, asteroids)
        @test all(supports_massless_encounter, comets)

        yandi = only(filter(body -> body.id == ID_YANDI, all_bodies))
        @test yandi.class == COMET
        @test supports_massless_encounter(yandi)
        @test !supports_massive_flyby(yandi)
    end

    @testset "Physical Data Minimums" begin
        planets, asteroids, comets, all_bodies = load_all_bodies()

        for body in planets
            @test body.μ > 0.0
            @test body.R > 0.0
            @test isfinite(orbital_period(body))
            @test orbital_period(body) > 0.0
        end

        for body in vcat(asteroids, comets)
            @test body.μ == 0.0
            @test body.R == 0.0
            @test isfinite(orbital_period(body))
            @test orbital_period(body) > 0.0
        end

        for body in all_bodies
            @test isfinite(body.elements.a)
            @test isfinite(body.elements.e)
            @test isfinite(body.elements.i)
            @test isfinite(body.elements.Ω)
            @test isfinite(body.elements.ω)
            @test isfinite(body.elements.M0)
            @test isfinite(body.w_body)

            for t in range(T_LAUNCH_JD, T_HORIZON_JD; length=5)
                r, v = kepler_propagate(body.elements, t, MU_ALTAIRA)
                @test all(isfinite, r)
                @test all(isfinite, v)
            end
        end
    end

    @testset "Units And Constants" begin
        @test isapprox(AU_KM * GTOC13.KM_TO_AU, 1.0; atol=1e-12)
        @test DAY_S == 86400.0
        @test isapprox(GTOC13.T_HORIZON_DAYS, 200.0 * YEAR_DAYS; atol=1e-12)
        @test GTOC13.SAIL_AREA == 15000.0
        @test GTOC13.SAIL_MASS == 500.0
        @test 0.0 < GTOC13.SAIL_BETA < 1.0
    end

    @testset "Loader Robustness" begin
        with_temp_raw_copy() do tmpdir
            path = joinpath(tmpdir, GTOC13.PLANETS_FILENAME)
            lines = readlines(path)
            lines[1] = "wrong,header"
            write_lines(path, lines)

            msg = error_message(() -> load_all_bodies(tmpdir))
            @test occursin("Unexpected header", msg)
        end

        with_temp_raw_copy() do tmpdir
            path = joinpath(tmpdir, GTOC13.ASTEROIDS_FILENAME)
            lines = readlines(path)
            lines[2] = string(csv_fields(lines[2])[1], ",NaN,0.193,7.865,43.147,212.678,42.389,1")
            write_lines(path, lines)

            msg = error_message(() -> load_all_bodies(tmpdir))
            @test occursin("non-finite numeric value", msg)
        end

        with_temp_raw_copy() do tmpdir
            path = joinpath(tmpdir, GTOC13.COMETS_FILENAME)
            lines = readlines(path)
            lines[2] = first(split(lines[2], ",")) * ",1,2"
            write_lines(path, lines)

            msg = error_message(() -> load_all_bodies(tmpdir))
            @test occursin("Invalid small-body row", msg)
        end

        with_temp_raw_copy() do tmpdir
            path = joinpath(tmpdir, GTOC13.PLANETS_FILENAME)
            lines = readlines(path)
            push!(lines, lines[end])
            write_lines(path, lines)

            msg = error_message(() -> load_all_bodies(tmpdir))
            @test occursin("Duplicate body IDs", msg)
        end

        with_temp_raw_copy() do tmpdir
            path = joinpath(tmpdir, GTOC13.ASTEROIDS_FILENAME)
            lines = readlines(path)
            shuffled = vcat(lines[1:1], reverse(lines[2:end]))
            write_lines(path, shuffled)

            _, asteroids, _, _ = load_all_bodies(tmpdir)
            @test [body.id for body in asteroids] == collect(GTOC13.ASTEROID_ID_MIN:GTOC13.ASTEROID_ID_MAX)
        end
    end

    @testset "Processed Roundtrip" begin
        ids = [body.id for body in load_all_bodies()[4]]
        mktempdir() do tmpdir
            out_path = joinpath(tmpdir, "bodies.jld2")
            build_processed_bodies(; out_path=out_path)
            loaded = load_bodies(out_path)

            @test [body.id for body in loaded] == ids
            @test loaded[1].name == load_all_bodies()[4][1].name
            @test loaded[end].id == load_all_bodies()[4][end].id
        end
    end
end
