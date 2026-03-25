"""
Sequence feasibility checker.

Given a fixed backbone sequence, answers:
  - FEASIBLE / DOUBTFUL / INFEASIBLE
  - approximate total cost

This is called by the beam search before committing a node.
"""

@enum SequenceFeasibility begin
    SEQ_FEASIBLE
    SEQ_DOUBTFUL
    SEQ_INFEASIBLE
end

struct FeasibilityReport
    status        :: SequenceFeasibility
    total_cost    :: Float64
    bottleneck_leg :: Int   # index of hardest leg, -1 if all easy
    notes         :: String
end

"""
Check feasibility of a backbone sequence (list of events with fixed times).
"""
function check_sequence_feasibility(events::Vector{Event},
                                     bodies::Vector{Body},
                                     μ::Float64, β::Float64)
    # TODO: solve each leg in sequence, accumulate cost, flag bottlenecks
    return FeasibilityReport(SEQ_DOUBTFUL, Inf, -1, "not implemented")
end
