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

is_flyby_event(ev::Event) = ev.event_type ∈ (EVT_MASSIVE_FLYBY, EVT_MASSLESS_ENCOUNTER)

function events_nondecreasing(events)
    return issorted(map(ev -> ev.t, events))
end

function require_nondecreasing_event_times(events)
    events_nondecreasing(events) && return true
    error("Event times must be nondecreasing")
end

function successive_same_body_flybys(prev::Event, next::Event)
    return is_flyby_event(prev) &&
           is_flyby_event(next) &&
           prev.body_id > 0 &&
           prev.body_id == next.body_id
end

function require_adjacent_reflyby_spacing(events, bodies_by_id::Dict{Int,Body};
                                          μ_central::Float64=MU_ALTAIRA)
    require_nondecreasing_event_times(events)
    for (prev, next) in zip(events, events[2:end])
        successive_same_body_flybys(prev, next) || continue
        body = get(bodies_by_id, prev.body_id, nothing)
        isnothing(body) && error("Missing body $(prev.body_id) for reflyby spacing check")
        require_flyby_revisit_spacing(body, prev.t, next.t; μ_central=μ_central)
    end
    return true
end

function launch_event(state::CartesianState, resources_after::MissionResources;
                      leg::Union{Leg,Nothing}=nothing,
                      score_contribution::Float64=0.0)
    require_within_mission_window(resources_after, state.t)
    return Event(-1, EVT_LAUNCH, state.t, state, leg, score_contribution, resources_after)
end

function end_event(state::CartesianState, resources_after::MissionResources;
                   leg::Union{Leg,Nothing}=nothing,
                   score_contribution::Float64=0.0)
    require_within_mission_window(resources_after, state.t)
    return Event(-1, EVT_END, state.t, state, leg, score_contribution, resources_after)
end

"""
Construct a perihelion event after validating mission-window consistency.
"""
function perihelion_event(state::CartesianState, resources_after::MissionResources;
                          leg::Union{Leg,Nothing}=nothing,
                          score_contribution::Float64=0.0)
    require_within_mission_window(resources_after, state.t)
    return Event(-1, EVT_PERIHELION, state.t, state, leg, score_contribution, resources_after)
end

"""
Construct a massive-flyby event from a massive body.
"""
function massive_flyby_event(body::Body, state::CartesianState, resources_after::MissionResources;
                             leg::Union{Leg,Nothing}=nothing,
                             score_contribution::Float64=0.0)
    supports_massive_flyby(body) || error("Body $(body.id) cannot generate a massive flyby event")
    require_within_mission_window(resources_after, state.t)
    return Event(body.id, EVT_MASSIVE_FLYBY, state.t, state, leg, score_contribution, resources_after)
end

"""
Construct a massless-encounter event from a massless body.
"""
function massless_encounter_event(body::Body, state::CartesianState, resources_after::MissionResources;
                                  leg::Union{Leg,Nothing}=nothing,
                                  score_contribution::Float64=0.0)
    supports_massless_encounter(body) || error("Body $(body.id) cannot generate a massless encounter event")
    require_within_mission_window(resources_after, state.t)
    return Event(body.id, EVT_MASSLESS_ENCOUNTER, state.t, state, leg, score_contribution, resources_after)
end
