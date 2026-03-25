module GTOC13

using JLD2
using LinearAlgebra
using StaticArrays

export BodyClass, BodyId, EventType, LegType, SequenceFeasibility
export STAR, PLANET, ASTEROID, COMET, MOON
export EVT_PERIHELION, EVT_MASSIVE_FLYBY, EVT_MASSLESS_ENCOUNTER, EVT_LAUNCH, EVT_END
export LEG_COAST, LEG_SAIL, LEG_PATCHED_CONIC
export SEQ_FEASIBLE, SEQ_DOUBTFUL, SEQ_INFEASIBLE
export Body, OrbitalElements, EphemerisSegment
export CartesianState, KeplerianState, SailAttitude, Leg
export MissionResources, EncounterCandidate, Event
export BodyScoreMemory, ScoreState, ScoredMission
export BackboneNode, BeamLabel, HarvestNode, BoundReport, BeamSearchResult
export BeamSearchConfig, FeasibilityReport, RunLogger, RunMetrics
export AU_KM, DAY_S, YEAR_DAYS, MU_ALTAIRA, T_LAUNCH_JD, T_HORIZON_JD
export R_DEEP_PERIHELION, R_NORMAL_PERIHELION
export BODY_WEIGHTS, ID_YANDI
export solve_kepler, eccentric_to_true, mean_motion, kepler_propagate
export propagate_state, state_to_elements
export is_deep_perihelion, is_perihelion, find_perihelion_time
export flyby_turn_angle, max_turn_angle, min_periapsis_for_turn
export flyby_v_out_family, flyby_altitude, flyby_altitude_feasible
export heliocentric_direction, ecliptic_lon_lat
export load_all_bodies, load_bodies, build_processed_bodies, load_ephemerides
export consume_deep_perihelion, consume_perihelion, visit_planet, harvest_body
export body_weight, is_planet, is_massless
export seasonal_factor, seasonal_factor_upper_bound
export vinf_factor, vinf_auday_to_kms, vinf_factor_upper_bound
export grand_tour_bonus, grand_tour_bonus_ub
export exact_score, optimistic_score_upper_bound
export make_root_node, extend_node, generate_branches
export score_upper_bound_v0, should_prune
export beam_search, best_first_search, dominates, remove_dominated
export check_sequence_feasibility
export compute_metrics, print_run_summary
export clear_caches!

# Order matters: types first, then everything that depends on them.

include("types/bodies.jl")
include("types/state.jl")
include("types/mission.jl")
include("types/events.jl")
include("types/score.jl")
include("types/search.jl")

include("physics/constants.jl")
include("physics/kepler.jl")
include("physics/perihelion.jl")
include("physics/sail_dynamics.jl")
include("physics/patched_conics.jl")
include("physics/encounters.jl")
include("physics/frames.jl")

include("io/load_statement_data.jl")
include("io/load_ephemerides.jl")
include("io/save_results.jl")

include("score/weights.jl")
include("score/seasonal_factor.jl")
include("score/vinf_factor.jl")
include("score/grand_tour_bonus.jl")
include("score/harvesting_state.jl")

include("search/node_state.jl")
include("search/branching.jl")
include("search/dominance.jl")
include("search/bounds.jl")
include("search/beam_search.jl")
include("search/best_first.jl")
include("search/cut_pool.jl")

include("local_solver/leg_models.jl")
include("local_solver/coast_leg.jl")
include("local_solver/sail_leg_v0.jl")
include("local_solver/massive_flyby_leg.jl")
include("local_solver/massless_encounter_leg.jl")
include("local_solver/sequence_feasibility.jl")
include("local_solver/sequence_refinement.jl")

include("relaxations/optimistic_backbone.jl")
include("relaxations/optimistic_harvesting.jl")
include("relaxations/seasonal_relaxation.jl")
include("relaxations/sail_convex_stub.jl")
include("relaxations/benders_like_cuts.jl")

include("analysis/metrics.jl")
include("analysis/pareto.jl")
include("analysis/diagnostics.jl")
include("analysis/logging.jl")

include("utils/numerics.jl")
include("utils/interpolation.jl")
include("utils/memoization.jl")
include("utils/pretty.jl")

end # module
