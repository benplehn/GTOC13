"""
Load body data from the GTOC13 raw CSV files shipped by the competition.

The official files use:
  - km for distances
  - km^3/s^2 for GM
  - degrees for angles

This loader normalizes everything into the solver's internal units:
  - AU for distances
  - AU^3/day^2 for GM
  - radians for angles
"""

const PLANETS_FILENAME = "gtoc13_planets.csv"
const ASTEROIDS_FILENAME = "gtoc13_asteroids.csv"
const COMETS_FILENAME = "gtoc13_comets.csv"
const PACKAGE_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const PLANETS_HEADER_FIELDS = [
    "#Planet ID",
    "Name",
    "GM (km3/s2)",
    "Radius (km)",
    "Semi-Major Axis (km)",
    "Eccentricity ()",
    "Inclination (deg)",
    "Longitude of the Ascending Node (deg)",
    "Argument of Periapsis (deg)",
    "Mean Anomaly at t=0 (deg)",
    "Weight ()",
]
const ASTEROIDS_HEADER_FIELDS = [
    "#Asteroid ID",
    "Semi-Major Axis (km)",
    "Eccentricity ()",
    "Inclination (deg)",
    "Longitude of the Ascending Node (deg)",
    "Argument of Periapsis (deg)",
    "Mean Anomaly at t=0",
    "Weight ()",
]
const COMETS_HEADER_FIELDS = [
    "# Comet ID",
    "Semi-Major Axis (km)",
    "Eccentricity ()",
    "Inclination (deg)",
    "Longitude of the Ascending Node (deg)",
    "Argument of Periapsis (deg)",
    "Mean Anomaly at t=0 (deg)",
    "Weight ()",
]

package_path(parts...) = normpath(joinpath(PACKAGE_ROOT, parts...))

strip_csv_field(field::AbstractString) = strip(replace(field, '\r' => ""))

function parse_csv_float(field::AbstractString)
    value = parse(Float64, strip_csv_field(field))
    isfinite(value) || error("Encountered non-finite numeric value: $(repr(field))")
    return value
end

function parse_csv_int(field::AbstractString)
    value = parse(Int, strip_csv_field(field))
    return value
end

normalized_header_fields(line::AbstractString) = strip_csv_field.(split(strip_csv_field(line), ','))

function expected_header_fields(class::BodyClass)
    class == PLANET && return PLANETS_HEADER_FIELDS
    class == ASTEROID && return ASTEROIDS_HEADER_FIELDS
    class == COMET && return COMETS_HEADER_FIELDS
    error("Unsupported body class for CSV header validation: $(class)")
end

function validate_header(line::AbstractString, class::BodyClass, path::String)
    fields = normalized_header_fields(line)
    expected = expected_header_fields(class)
    fields == expected || error("Unexpected header in $(path). Expected $(expected), got $(fields)")
    return fields
end

function validate_unique_ids(bodies::Vector{Body}, label::String)
    ids = [body.id for body in bodies]
    length(ids) == length(unique(ids)) || error("Duplicate body IDs detected in $(label)")
    return true
end

function default_body_name(body_id::Int, class::BodyClass)
    class == ASTEROID && return "Asteroid $(body_id)"
    class == COMET && return "Comet $(body_id)"
    return "Body $(body_id)"
end

function orbital_elements_from_csv(a_km::Float64, e::Float64, i_deg::Float64,
                                   Ω_deg::Float64, ω_deg::Float64, M0_deg::Float64)
    return OrbitalElements(
        km_to_au(a_km),
        e,
        deg_to_rad(i_deg),
        deg_to_rad(Ω_deg),
        deg_to_rad(ω_deg),
        deg_to_rad(M0_deg),
        T_LAUNCH_JD,
    )
end

function validate_weight(body_id::Int, csv_weight::Float64)
    expected = body_weight(body_id)
    if !isapprox(csv_weight, expected; atol=1e-12, rtol=0.0)
        @warn "Weight mismatch in CSV; using canonical statement weight" body_id csv_weight expected
    end
    return expected
end

function parse_planet_row(fields::Vector{SubString{String}})
    length(fields) == 11 || error("Invalid planets row with $(length(fields)) columns")

    body_id = parse_csv_int(fields[1])
    name = String(strip_csv_field(fields[2]))
    gm_km3s2 = parse_csv_float(fields[3])
    radius_km = parse_csv_float(fields[4])
    a_km = parse_csv_float(fields[5])
    e = parse_csv_float(fields[6])
    i_deg = parse_csv_float(fields[7])
    Ω_deg = parse_csv_float(fields[8])
    ω_deg = parse_csv_float(fields[9])
    M0_deg = parse_csv_float(fields[10])
    csv_weight = parse_csv_float(fields[11])

    class = body_id == ID_YANDI ? COMET : PLANET
    a_km > 0.0 || error("Semi-major axis must be positive for body $(body_id)")
    μ = class == PLANET ? μ_km3s2_to_au3day2(gm_km3s2) : 0.0
    R = class == PLANET ? km_to_au(radius_km) : 0.0
    if class == PLANET
        μ > 0.0 || error("Planet $(body_id) must have positive GM")
        R > 0.0 || error("Planet $(body_id) must have positive radius")
    end

    return Body(
        body_id,
        isempty(name) ? default_body_name(body_id, class) : name,
        class,
        μ,
        R,
        orbital_elements_from_csv(a_km, e, i_deg, Ω_deg, ω_deg, M0_deg),
        validate_weight(body_id, csv_weight),
    )
end

function parse_small_body_row(fields::Vector{SubString{String}}, class::BodyClass)
    length(fields) == 8 || error("Invalid small-body row with $(length(fields)) columns")

    body_id = parse_csv_int(fields[1])
    a_km = parse_csv_float(fields[2])
    e = parse_csv_float(fields[3])
    i_deg = parse_csv_float(fields[4])
    Ω_deg = parse_csv_float(fields[5])
    ω_deg = parse_csv_float(fields[6])
    M0_deg = parse_csv_float(fields[7])
    csv_weight = parse_csv_float(fields[8])
    a_km > 0.0 || error("Semi-major axis must be positive for body $(body_id)")

    return Body(
        body_id,
        default_body_name(body_id, class),
        class,
        0.0,
        0.0,
        orbital_elements_from_csv(a_km, e, i_deg, Ω_deg, ω_deg, M0_deg),
        validate_weight(body_id, csv_weight),
    )
end

function load_body_file(path::String, class::BodyClass)
    isfile(path) || error("Body CSV not found: $path")

    lines = readlines(path)
    length(lines) >= 2 || error("Body CSV is empty: $path")
    validate_header(lines[1], class, path)

    bodies = Body[]
    for offset in eachindex(lines[2:end])
        line_idx = offset + 1
        line = lines[line_idx]
        isempty(strip_csv_field(line)) && error("Blank line found at $(path):$(line_idx)")
        fields = split(line, ',')
        body = class == PLANET ? parse_planet_row(fields) : parse_small_body_row(fields, class)
        push!(bodies, body)
    end

    validate_unique_ids(bodies, path)
    sort!(bodies, by=body -> body.id)
    return bodies
end

"""
Load the raw competition CSV files.
Returns `(planets, asteroids, comets, all_bodies)`.
"""
function load_all_bodies(data_dir::String=package_path("data", "raw"))
    planets = load_body_file(joinpath(data_dir, PLANETS_FILENAME), PLANET)
    asteroids = load_body_file(joinpath(data_dir, ASTEROIDS_FILENAME), ASTEROID)
    comets = load_body_file(joinpath(data_dir, COMETS_FILENAME), COMET)

    # Yandi lives in the planets CSV but is dynamically massless, so only the
    # truly massive planets stay in the planets bucket.
    massive_planets = filter(body -> body.class == PLANET, planets)
    all_bodies = sort!(vcat(planets, asteroids, comets), by=body -> body.id)
    validate_unique_ids(all_bodies, "combined body catalogue")

    return massive_planets, asteroids, comets, all_bodies
end

"""
Build the processed JLD2 body artifact from the raw CSV files.
"""
function build_processed_bodies(raw_dir::String=package_path("data", "raw");
                                out_path::String=package_path("data", "processed", "bodies.jld2"))
    planets, asteroids, comets, all_bodies = load_all_bodies(raw_dir)
    mkpath(dirname(out_path))
    jldsave(
        out_path;
        planets=planets,
        asteroids=asteroids,
        comets=comets,
        all_bodies=all_bodies,
    )
    return out_path
end

"""
Load the processed body artifact built by `build_processed_bodies`.
"""
function load_bodies(path::String=package_path("data", "processed", "bodies.jld2"))
    isfile(path) || error("Processed body file not found: $path")
    return sort!(JLD2.load(path, "all_bodies"), by=body -> body.id)
end
