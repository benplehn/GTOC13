"""
Grand tour bonus b — from GTOC13 problem statement §3.1.

b = 1.2 if the solution has a scientific flyby of:
  - all 10 planets (IDs 1–10)
  - dwarf planet Yandi (ID 1000)
  - at least 13 asteroids or comets (IDs 1001–1257 or 2001–2042)
Otherwise b = 1.
"""

"""
Compute the grand tour bonus b given the current set of scientifically flown bodies.
Returns 1.2 if all conditions are met, 1.0 otherwise.
"""
function grand_tour_bonus(planets_and_yandi_visited::Set{Int},
                           n_small_bodies_visited::Int)
    GRAND_TOUR_REQUIRED_PLANETS ⊆ planets_and_yandi_visited || return 1.0
    n_small_bodies_visited ≥ GRAND_TOUR_MIN_SMALL_BODIES   || return 1.0
    return GRAND_TOUR_BONUS_B
end

"""
Bonus score contribution from grand tour.
The bonus multiplies the entire score, so its "additive contribution"
is (b - 1) * current_base_score.

For upper bound purposes: if grand tour is achievable,
multiply the remaining score estimate by GRAND_TOUR_BONUS_B.
"""
function grand_tour_bonus_ub(planets_and_yandi_visited::Set{Int},
                               n_small_bodies_visited::Int,
                               n_small_bodies_reachable::Int)
    # Already achieved
    if GRAND_TOUR_REQUIRED_PLANETS ⊆ planets_and_yandi_visited &&
       n_small_bodies_visited ≥ GRAND_TOUR_MIN_SMALL_BODIES
        return GRAND_TOUR_BONUS_B
    end
    # Missing planets: check if still achievable (optimistic: yes if n_reachable ≥ needed)
    missing_small = max(0, GRAND_TOUR_MIN_SMALL_BODIES - n_small_bodies_visited)
    if n_small_bodies_reachable ≥ missing_small
        return GRAND_TOUR_BONUS_B   # optimistic: achievable
    end
    return 1.0
end
