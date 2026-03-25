"""
Score accounting types.

The score is NOT just a terminal value. It has internal state (seasonal memory,
grand-tour accumulation) that must be tracked alongside the mission history.
This struct IS that state.
"""

"""
Per-body score memory. Tracks the encounter directions already "used",
which feeds the seasonal penalty S.
"""
struct BodyScoreMemory
    body_id :: Int
    # Unit vectors (heliocentric) of all encounters so far, in order.
    encounter_directions :: Vector{SVector{3, Float64}}
    # Running sum of score contributions from this body.
    accumulated_score :: Float64
end

"""
Global score state at a point in the mission history.
This is what the search node must carry (or be able to reconstruct).
"""
struct ScoreState
    # Per-body memory for seasonal factor computation.
    body_memories :: Dict{Int, BodyScoreMemory}
    # Score from backbone events (perihelion, flyby) so far.
    backbone_score :: Float64
    # Score from harvesting (massless encounters) so far.
    harvest_score :: Float64
    # Grand-tour bonus accumulated so far (0 until all required planets visited).
    grand_tour_bonus :: Float64
    # Total exact score = backbone_score + harvest_score + grand_tour_bonus
    total_exact :: Float64
end

"""
A complete scored mission trajectory, ready for submission or analysis.
"""
struct ScoredMission
    events   :: Vector{Event}
    resources :: MissionResources
    score    :: ScoreState
    # Human-readable summary for logging
    label    :: String
end
