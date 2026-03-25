@testset "Units And Conventions" begin
    @test AU_KM == 149597870.691
    @test DAY_S == 86400.0
    @test YEAR_DAYS == 365.25
    @test GTOC13.MU_ALTAIRA_KM3S2 == 139348062043.343

    @test isapprox(km_to_au(AU_KM), 1.0; atol=1e-12, rtol=0.0)
    @test isapprox(au_to_km(1.0), AU_KM; atol=1e-9, rtol=0.0)
    @test isapprox(seconds_to_days(DAY_S), 1.0; atol=1e-12, rtol=0.0)
    @test isapprox(days_to_seconds(1.0), DAY_S; atol=1e-12, rtol=0.0)
    @test isapprox(years_to_days(1.0), YEAR_DAYS; atol=1e-12, rtol=0.0)
    @test isapprox(days_to_years(YEAR_DAYS), 1.0; atol=1e-12, rtol=0.0)
    @test isapprox(deg_to_rad(180.0), π; atol=1e-12, rtol=0.0)
    @test isapprox(rad_to_deg(π), 180.0; atol=1e-12, rtol=0.0)
    @test isapprox(μ_km3s2_to_au3day2(GTOC13.MU_ALTAIRA_KM3S2), MU_ALTAIRA; atol=1e-18, rtol=1e-12)
    @test isapprox(μ_au3day2_to_km3s2(MU_ALTAIRA), GTOC13.MU_ALTAIRA_KM3S2; atol=1e-6, rtol=1e-12)

    speed_kms = 12.345
    @test isapprox(auday_to_kms(kms_to_auday(speed_kms)), speed_kms; atol=1e-12, rtol=1e-12)
    accel_kms2 = GTOC13.A_CHAR_KM_S2
    @test isapprox(auday2_to_kms2(kms2_to_auday2(accel_kms2)), accel_kms2; atol=1e-18, rtol=1e-12)
    @test isapprox(vinf_auday_to_kms(kms_to_auday(speed_kms)), speed_kms; atol=1e-12, rtol=1e-12)

    res = MissionResources(T_LAUNCH_JD, T_HORIZON_JD)
    @test !event_within_mission_window(res, days_to_seconds(1.0))

    msg = error_message(() -> OrbitalElements(1.0, 0.1, 180.0, 0.0, 0.0, 0.0, 0.0))
    @test occursin("radians", msg)

    msg = error_message(() -> GTOC13.perifocal_rotation(0.0, 0.0, 180.0))
    @test occursin("radians", msg)

    msg = error_message(() -> SailAttitude(0.0, 180.0))
    @test occursin("radians", msg)

    msg = error_message(() -> CartesianState(0.0, SVector(AU_KM, 0.0, 0.0), SVector(0.0, 0.01, 0.0)))
    @test occursin("km vs AU", msg)

    msg = error_message(() -> OrbitalElements(AU_KM, 0.1, 0.1, 0.1, 0.1, 0.1, 0.0))
    @test occursin("km vs AU", msg)
end
