"""
Discrete events along the mission timeline.

An event is a point in (time, space) where the spacecraft interacts with a body
or crosses a threshold. Events are the nodes the search branches on.
"""

@enum EventType begin
    EVT_PERIHELION          # r < threshold, no body interaction
    EVT_MASSIVE_FLYBY       # patched-conic flyby of a planet
    EVT_MASSLESS_ENCOUNTER  # matching V_inf with a small body
    EVT_LAUNCH              # mission start
    EVT_END                 # mission end / time horizon
end

"""
A candidate event: not yet decided, lives in the branching frontier.
"""
struct EncounterCandidate
    body_id      :: Int
    event_type   :: EventType
    t_earliest   :: Float64   # earliest feasible time [JD]
    t_latest     :: Float64   # latest feasible time [JD]
    # Geometry hint for ranking / pruning
    v_inf_approx :: Float64   # estimated V_inf at encounter [AU/day]
    Δv_approx    :: Float64   # estimated transfer cost [AU/day]
    score_upper  :: Float64   # optimistic score contribution
end

"""
A realized event: committed to the mission history.
"""
struct Event
    body_id    :: Int
    event_type :: EventType
    t          :: Float64
    # State of spacecraft at event (post-maneuver for flyby/encounter)
    state      :: CartesianState
    # Leg that brought us here from the previous event
    leg        :: Union{Leg, Nothing}
    # Score contribution of this event (exact, not optimistic)
    score_contribution :: Float64
    # Resource delta applied by this event
    resources_after :: MissionResources
end
