"""
Node construction and accessors.
"""

let _node_counter = Ref(0)
    global next_node_id() = (_node_counter[] += 1)
end

"""
Create the root node for a search run.
"""
function make_root_node(launch_state::CartesianState,
                         resources::MissionResources)
    empty_score = ScoreState(Dict(), 0.0, 0.0, 0.0, 0.0)
    BackboneNode(
        next_node_id(), 0,
        launch_state, resources, empty_score,
        Event[],
        0.0, Inf,   # score_exact, score_ub (unbounded at root)
        0, false
    )
end

"""
Extend a node with a new committed event.
Returns the child node (parent unchanged).
"""
function extend_node(parent::BackboneNode, ev::Event,
                      new_resources::MissionResources,
                      new_score::ScoreState,
                      score_ub::Float64)
    BackboneNode(
        next_node_id(),
        parent.depth + 1,
        ev.state,
        new_resources,
        new_score,
        vcat(parent.history, ev),
        new_score.total_exact,
        score_ub,
        parent.id,
        false
    )
end
