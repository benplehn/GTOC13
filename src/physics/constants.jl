"""
Physical and problem constants — all values from GTOC13 problem statement.
Units: AU, days, km where noted.
"""

# --- Altaira gravitational parameter ---
const MU_ALTAIRA_KM3S2 = 139348062043.343     # [km³/s²]
# Convert to [AU³/day²]
const AU_KM             = 149597870.691        # [km/AU]  (exact from statement)
const DAY_S             = 86400.0              # [s/day]
const YEAR_DAYS         = 365.25               # [days/year]
const DEG2RAD           = π / 180.0
const KM_TO_AU          = 1.0 / AU_KM
const KM3S2_TO_AU3DAY2  = (DAY_S^2) / (AU_KM^3)
const MU_ALTAIRA        = MU_ALTAIRA_KM3S2 * (DAY_S^2) / (AU_KM^3)  # [AU³/day²]

# --- Solar sail parameters ---
const SAIL_C_SI   = 5.4026e-6    # Altaira flux at 1 AU [N/m²]
const SAIL_AREA   = 15000.0      # sail area [m²]
const SAIL_MASS   = 500.0        # spacecraft mass [kg]
# Characteristic acceleration at 1 AU [km/s²]
const SAIL_BETA_KM_S2 = 2 * SAIL_C_SI * SAIL_AREA / SAIL_MASS * 1e-3
# Sail lightness number β = a_sail(1AU) / g_Altaira(1AU)
# g_Altaira at 1 AU = μ / (1 AU in km)²
const G_ALTAIRA_1AU_KM_S2 = MU_ALTAIRA_KM3S2 / AU_KM^2
const SAIL_BETA = SAIL_BETA_KM_S2 / G_ALTAIRA_1AU_KM_S2

# --- Mission time window ---
const T_MISSION_YEARS = 200.0
const T_HORIZON_DAYS  = T_MISSION_YEARS * YEAR_DAYS   # [days]
# t0 ∈ [0, 200 years]. t=0 is reference epoch for orbital elements.
const T_LAUNCH_JD      = 0.0
const T_HORIZON_JD     = T_HORIZON_DAYS

# --- Perihelion thresholds ---
const R_DEEP_PERIHELION   = 0.01   # [AU] — one allowed passage this close
const R_NORMAL_PERIHELION = 0.05   # [AU] — all other perihelion passages must be ≥ this
const PERIHELION_CHECKER_TOL_AU = KM_TO_AU   # [AU] — 1 km checker tolerance

# --- Flyby altitude constraints ---
const FLYBY_ALT_MIN_RADII = 0.1    # [body radii]
const FLYBY_ALT_MAX_RADII = 100.0  # [body radii]
const FLYBY_POSITION_TOL_AU = KM_TO_AU       # [AU] — 1 km position-match tolerance

# --- Same-body re-flyby minimum interval ---
const REFLYBY_PERIOD_FRACTION = 1.0 / 3.0   # min interval = orbital_period / 3

# --- Max scientific flybys per body ---
const MAX_SCIENTIFIC_FLYBYS_PER_BODY = 13

# --- Body ID ranges ---
const PLANET_ID_MIN   = 1
const PLANET_ID_MAX   = 10
const YANDI_ID        = 1000
const ASTEROID_ID_MIN = 1001
const ASTEROID_ID_MAX = 1257
const COMET_ID_MIN    = 2001
const COMET_ID_MAX    = 2042

# --- Body IDs (planets in order of increasing orbital period) ---
const ID_VULCAN    = 1
const ID_YAVIN     = 2
const ID_EDEN      = 3
const ID_HOTH      = 4
const ID_YANDI     = 1000   # dwarf planet — massless for scoring
const ID_BEYONCE   = 5
const ID_BESPIN    = 6
const ID_JOTUNN    = 7
const ID_WAKONYINGO = 8
const ID_ROGUE1    = 9
const ID_PLANETX   = 10

# --- Body scientific weights (Table 1) ---
const BODY_WEIGHTS = Dict{Int, Float64}(
    ID_VULCAN     => 0.1,
    ID_YAVIN      => 1.0,
    ID_EDEN       => 2.0,
    ID_HOTH       => 3.0,
    ID_YANDI      => 5.0,
    ID_BEYONCE    => 7.0,
    ID_BESPIN     => 10.0,
    ID_JOTUNN     => 15.0,
    ID_WAKONYINGO => 20.0,
    ID_ROGUE1     => 35.0,
    ID_PLANETX    => 50.0,
    # Asteroids 1001–1257 → weight 1 (populated at load time)
    # Comets 2001–2042   → weight 3 (populated at load time)
)

# --- Grand tour bonus ---
# b = 1.2 if all 10 planets + Yandi + ≥13 asteroids/comets are scientifically flown by
const GRAND_TOUR_BONUS_B        = 1.2
const GRAND_TOUR_MIN_SMALL_BODIES = 13
const GRAND_TOUR_REQUIRED_PLANETS = Set([
    ID_VULCAN, ID_YAVIN, ID_EDEN, ID_HOTH,
    ID_BEYONCE, ID_BESPIN, ID_JOTUNN, ID_WAKONYINGO,
    ID_ROGUE1, ID_PLANETX, ID_YANDI
])  # all 10 planets + Yandi

# --- Time bonus c (competition time-dependent, days from competition start) ---
function time_bonus_c(t_competition_days::Float64)
    t_competition_days ≤ 7.0 && return 1.13
    return -0.005 * t_competition_days + 1.165
end

# --- Initial spacecraft state ---
const SC_INITIAL_X  = -200.0   # [AU]
const SC_INITIAL_VY = 0.0
const SC_INITIAL_VZ = 0.0
# Vx, y, z are free design variables; t0 ∈ [0, 200 years]
