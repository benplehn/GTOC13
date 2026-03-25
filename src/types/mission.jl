"""
Mission-level resource accounting.
This is the "memory" that the score and search must both respect.

Design note: MissionResources is immutable and copyable so that search nodes
can fork it cheaply. All fields map to statement-defined constraints.
"""
struct MissionResources
    # --- Time ---
    t_launch    :: Float64   # mission start epoch [JD]
    t_horizon   :: Float64   # mission end epoch [JD]  (from statement)

    # --- Perihelion budget ---
    # True once the spacecraft has crossed r < 0.01 AU (deep perihelion).
    deep_perihelion_used :: Bool
    # Count of standard perihelion passages (r < 0.05 AU) performed so far.
    perihelion_count     :: Int

    # --- Score eligibility ---
    # Small bodies only contribute score AFTER the first perihelion.
    first_perihelion_done :: Bool

    # --- Grand-tour coverage ---
    # Set of planet ids visited as massive flybys so far.
    planets_visited :: Set{Int}

    # --- Harvesting ---
    # Set of small body ids scored so far (each body scores at most once
    # unless re-encounter rules differ — check statement).
    bodies_harvested :: Set{Int}
end

"""
Construct the initial resource state at mission start.
"""
function MissionResources(t_launch::Float64, t_horizon::Float64)
    MissionResources(
        t_launch, t_horizon,
        false, 0, false,
        Set{Int}(), Set{Int}()
    )
end

"""
Return a new MissionResources after consuming the deep perihelion slot.
"""
function consume_deep_perihelion(r::MissionResources)
    @assert !r.deep_perihelion_used "Deep perihelion already consumed"
    MissionResources(
        r.t_launch, r.t_horizon,
        true, r.perihelion_count + 1, true,
        copy(r.planets_visited), copy(r.bodies_harvested)
    )
end

"""
Return a new MissionResources after a standard perihelion (r < 0.05 AU).
"""
function consume_perihelion(r::MissionResources)
    MissionResources(
        r.t_launch, r.t_horizon,
        r.deep_perihelion_used,
        r.perihelion_count + 1,
        true,   # first perihelion is now done
        copy(r.planets_visited), copy(r.bodies_harvested)
    )
end

"""
Return a new MissionResources after visiting a planet.
"""
function visit_planet(r::MissionResources, planet_id::Int)
    MissionResources(
        r.t_launch, r.t_horizon,
        r.deep_perihelion_used, r.perihelion_count, r.first_perihelion_done,
        push!(copy(r.planets_visited), planet_id),
        copy(r.bodies_harvested)
    )
end

"""
Return a new MissionResources after harvesting a small body.
"""
function harvest_body(r::MissionResources, body_id::Int)
    MissionResources(
        r.t_launch, r.t_horizon,
        r.deep_perihelion_used, r.perihelion_count, r.first_perihelion_done,
        copy(r.planets_visited),
        push!(copy(r.bodies_harvested), body_id)
    )
end
