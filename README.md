# GTOC13

Solver workspace for the 13th Global Trajectory Optimization Competition.

## Scope

The repository is currently cleaned up through:

- Phase 0: repository structure, core types, data layout, experiment/logging conventions
- Phase 1: raw CSV ingestion, processed body data build/load, constants, Kepler propagation, event/resource primitives

Later-phase search and local-solver modules remain in place, but are still explicitly marked as future work where appropriate.

## Layout

```text
GTOC13/
├─ Project.toml
├─ README.md
├─ data/
│  ├─ raw/          # competition CSV inputs
│  ├─ processed/    # JLD2 artifacts generated from raw data
│  └─ cache/        # precomputed search helpers
├─ configs/
├─ scripts/
├─ src/
└─ test/
```

## Data

Expected raw files:

- `data/raw/gtoc13_planets.csv`
- `data/raw/gtoc13_asteroids.csv`
- `data/raw/gtoc13_comets.csv`

These are parsed directly from the competition schema:

- distances in km are converted to AU
- gravitational parameters in km^3/s^2 are converted to AU^3/day^2
- angles in deg are converted to rad
- Yandi is loaded as a massless body even though it is listed in the planets CSV

Build processed body data with:

```bash
julia --project scripts/build_processed_data.jl
```

## Validation

Run tests with:

```bash
julia --project -e 'using Pkg; Pkg.test()'
```

Useful smoke checks:

```bash
julia --project -e 'using GTOC13; println(length(load_all_bodies()[4]))'
julia --project scripts/build_processed_data.jl
```

## Logging

- node-level logs use JSONL, one event per line
- processed body data is stored in `data/processed/bodies.jld2`
- mission and run summaries are written under `results/`
