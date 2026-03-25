# Phase 1 Coverage Matrix

This matrix is the gate for Phase 1. Each spec item must map to implementation,
tests, and a current status.

| Spec item | Functions / constants | Tests | Status |
| --- | --- | --- | --- |
| GTOC13 frame convention | `ReferenceFrame`, `vulcan_orbital_pole`, `gtoc13_reference_frame` | `test/test_frame_conventions.jl` | done |
| Initial spacecraft state and launch epoch bounds | `initial_epoch_days`, `initial_spacecraft_state`, `SC_INITIAL_X`, `SC_INITIAL_VY`, `SC_INITIAL_VZ` | `test/test_frame_conventions.jl`, `test/test_section1_integration.jl` | done |
| Constants and units | `AU_KM`, `DAY_S`, `YEAR_DAYS`, `T_HORIZON_DAYS`, sail constants, unit helpers | `test/test_data_loading.jl`, `test/test_units.jl` | done |
| Kepler equation residuals and regime coverage | `solve_kepler`, `solve_kepler_diagnostics` | `test/test_kepler.jl` | done |
| Keplerian coast propagation and invariants | `mean_motion`, `kepler_propagate`, `propagate_state` | `test/test_kepler.jl` | done |
| No numerical propagator on phase-1 coast path | `cached_kepler_propagate`, `solve_coast_leg`, `propagate_state` | `test/test_kepler.jl` | done |
| Elements → Cartesian conversion from statement formulas | `kepler_propagate`, `perifocal_rotation` | `test/test_elements_to_cartesian.jl` | done |
| Elements ↔ Cartesian round-trip policy | `state_to_elements`, `kepler_propagate` | `test/test_kepler.jl`, `test/test_elements_to_cartesian.jl` | done |
| 200-year mission window | `event_within_mission_window`, `require_within_mission_window`, `sequence_within_mission_window` | `test/test_mission_resources.jl`, `test/test_events.jl`, `test/test_section1_integration.jl` | done |
| Perihelion rule | `classify_perihelion_radius`, `perihelion_radius_allowed`, `require_perihelion_radius_allowed` | `test/test_mission_resources.jl`, `test/test_section1_integration.jl` | done |
| Perihelion checker tolerance policy | `PERIHELION_CHECKER_TOL_AU`, `classify_perihelion_radius` | `test/test_mission_resources.jl` | done |
| Re-flyby separation rule | `orbital_period`, `minimum_reflyby_separation`, `flyby_revisit_allowed`, `require_flyby_revisit_spacing`, `require_adjacent_reflyby_spacing` | `test/test_events.jl`, `test/test_section1_integration.jl` | done |
| Massive vs. massless distinction | `supports_massive_flyby`, `supports_massless_encounter`, `is_planet`, `is_massless` | `test/test_data_loading.jl`, `test/test_events.jl`, `test/test_patched_conics.jl` | done |
| Massive flyby V∞-norm semantics | `massive_vinf_magnitude_conserved`, `require_massive_vinf_magnitude_conserved`, `flyby_altitude_feasible` | `test/test_patched_conics.jl` | done |
| Massless encounter V∞-continuity semantics | `massless_vinf_continuous`, `require_massless_vinf_continuity` | `test/test_patched_conics.jl` | done |
| No asteroid/comet score before first perihelion | `massless_scoring_allowed`, `harvest_body`, `exact_score` | `test/test_mission_resources.jl`, `test/test_section1_integration.jl` | done |
| Sail cone-angle domain | `sail_cone_angle_in_domain`, `require_sail_cone_angle_in_domain`, `sail_normal_from_angles`, `SailAttitude` | `test/test_section1_integration.jl`, `test/test_units.jl` | done |
| Equality / checker tolerances | `STATE_ATOL`, `STATE_RTOL`, `VECTOR_ATOL`, `ANGLE_ATOL`, `state_approx_equal` | `test/test_helpers.jl`, `test/test_kepler.jl`, `test/test_section1_integration.jl` | done |
| Hidden epoch / angle convention consistency | `orbital_elements_from_csv`, `T_LAUNCH_JD`, `OrbitalElements` | `test/test_frame_conventions.jl`, `test/test_elements_to_cartesian.jl` | done |
| Angular branch cuts and quasi-singular policies | `kepler_propagate`, `state_to_elements` | `test/test_elements_to_cartesian.jl` | done |
| Cartesian → elements oracle agreement and singularity policy | `state_to_elements` | `test/test_elements_to_cartesian.jl` | done |
| Anti-silent unit mismatch checks | `OrbitalElements`, `CartesianState`, `SailAttitude`, `perifocal_rotation`, mission-window day checks | `test/test_units.jl` | done |
| Loader file integrity | `validate_header`, `parse_csv_float`, `load_body_file`, `validate_unique_ids` | `test/test_data_loading.jl` | done |
| Loader category counts and ID intervals | `load_all_bodies`, `is_planet`, `is_massless` | `test/test_data_loading.jl` | done |
| Loader physical minimums | `load_all_bodies`, `has_ephemeris_source`, `orbital_period` | `test/test_data_loading.jl` | done |
| Event constructors and node backbone minimal | `launch_event`, `end_event`, `perihelion_event`, `massive_flyby_event`, `massless_encounter_event`, `make_root_node` | `test/test_events.jl` | done |
| Event ordering and flyby position match | `events_nondecreasing`, `require_nondecreasing_event_times`, `same_position_at_flyby`, `require_same_position_at_flyby` | `test/test_events.jl` | done |
| Serialization and logging | `RunLogger`, `log_node!`, JLD2 round-trip | `test/test_events.jl` | done |
| Section 1 integrator scenario | root node, coast propagation, perihelion update, flyby, massless encounter | `test/test_section1_integration.jl` | done |

## Gate

Phase 1 is considered validated only if:

- this matrix remains fully `done`,
- `julia --project -e 'using Pkg; Pkg.test()'` passes,
- raw-body loading works from `data/raw/`,
- processed-body build/load works via `scripts/build_processed_data.jl`.
