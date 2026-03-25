"""
Score evaluation API.

Two public functions that the search engine must use:
  exact_score(history)         → ScoreState
  optimistic_score_upper_bound(node) → Float64
"""

"""
Compute the exact ScoreState from a complete or partial event history.
"""
function exact_score(history::Vector{Event}, resources::MissionResources)
    memories    = Dict{Int, BodyScoreMemory}()
    backbone_sc = 0.0
    harvest_sc  = 0.0

    for ev in history
        if ev.event_type == EVT_MASSLESS_ENCOUNTER
            # Only score if first perihelion is done
            !resources.first_perihelion_done && continue
            body_id = ev.body_id
            mem = get!(memories, body_id,
                       BodyScoreMemory(body_id, SVector{3,Float64}[], 0.0))
            dir = heliocentric_direction(ev.state.r)
            S   = seasonal_factor(dir, mem.encounter_directions)
            # Event does not yet store encounter-relative V∞ explicitly.
            # Until the local solver fills that in, use the admissible maximum.
            V   = vinf_factor_upper_bound()
            w   = body_weight(body_id)
            contrib = w * S * V
            new_dirs = vcat(mem.encounter_directions, [dir])
            memories[body_id] = BodyScoreMemory(body_id, new_dirs,
                                                mem.accumulated_score + contrib)
            harvest_sc += contrib

        elseif ev.event_type ∈ (EVT_MASSIVE_FLYBY, EVT_PERIHELION)
            backbone_sc += ev.score_contribution
        end
    end

    n_small_bodies = count(id -> is_massless(id) && id != ID_YANDI, resources.bodies_harvested)
    gt_multiplier = grand_tour_bonus(resources.planets_visited, n_small_bodies)
    total_base = backbone_sc + harvest_sc
    total = gt_multiplier * total_base
    return ScoreState(memories, backbone_sc, harvest_sc, gt_multiplier, total)
end

"""
Admissible upper bound on total score reachable from a BackboneNode.
This is the key pruning function. Must NEVER underestimate.
"""
function optimistic_score_upper_bound(node::BackboneNode,
                                       all_bodies::Vector{Body})
    exact_base = node.score_state.backbone_score + node.score_state.harvest_score
    # 1. Remaining backbone potential
    backbone_ub = optimistic_backbone_score(node, all_bodies)
    # 2. Remaining harvesting potential
    harvest_ub  = optimistic_harvesting_score(node, all_bodies)
    # 3. Grand tour bonus if still achievable
    n_small_visited = count(id -> is_massless(id) && id != ID_YANDI, node.resources.bodies_harvested)
    n_small_reachable = count(body -> is_massless(body.id) &&
                                     body.id != ID_YANDI &&
                                     !(body.id in node.resources.bodies_harvested),
                              all_bodies)
    gt_ub = grand_tour_bonus_ub(node.resources.planets_visited,
                                n_small_visited,
                                n_small_reachable)
    return gt_ub * (exact_base + backbone_ub + harvest_ub)
end
