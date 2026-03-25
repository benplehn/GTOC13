@testset "Sequence feasibility" begin
    # Empty sequence: trivially feasible
    report = check_sequence_feasibility(Event[], Body[], MU_ALTAIRA, 0.0)
    @test report isa FeasibilityReport
end
