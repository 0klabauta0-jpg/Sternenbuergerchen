#include "native_navigation.h"

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <limits>
#include <map>
#include <vector>
#include <godot_cpp/variant/vector2.hpp>

namespace godot {
namespace {
constexpr double infinity = std::numeric_limits<double>::infinity();

double hex_distance(const Vector2i &a, const Vector2i &b) {
    const int64_t dx = int64_t(a.x) - b.x;
    const int64_t dy = int64_t(a.y) - b.y;
    return static_cast<double>(std::max({std::abs(dx), std::abs(dy), std::abs(dx + dy)}));
}

Dictionary hpa_result(const Array &path, const char *status) {
    Dictionary result;
    result["path"] = path;
    result["status"] = status;
    return result;
}

struct ComponentState {
    double g = infinity;
    double f = infinity;
    Vector2i entry;
    Dictionary incoming;
    bool visited = false;
    bool open = false;
};

bool prune_lower_bound(double current, double base, double previous,
        const Vector2i &entry, const Vector2i &portal, const Vector2i &exit,
        const Vector2i &goal, bool includes_exit, double minimum) {
    if (minimum < 0.0 || !std::isfinite(current) || !std::isfinite(base) || !std::isfinite(previous)) {
        return false;
    }
    // Preserve the GDScript order of additions, including the conservative margin.
    double edge_lower_bound = base + hex_distance(entry, portal) * minimum;
    if (includes_exit) {
        edge_lower_bound += hex_distance(exit, goal) * minimum;
    }
    const double lower_bound = current + edge_lower_bound;
    if (!std::isfinite(lower_bound)) {
        return false;
    }
    const double margin = 0.000000001 * std::max(1.0, std::max(std::abs(lower_bound), std::abs(previous)));
    return lower_bound > previous + margin;
}

void append_unique(Array &path, const Vector2i &grid) {
    if (path.is_empty() || Vector2i(path[path.size() - 1]) != grid) {
        path.append(grid);
    }
}

Dictionary make_adjacency(const Array &portals) {
    Dictionary adjacency;
    for (int64_t i = 0; i < portals.size(); ++i) {
        const Dictionary portal = portals[i];
        for (int direction = 0; direction < 2; ++direction) {
            Dictionary edge;
            edge["portal_id"] = portal.get("portal_id", "");
            edge["from_component"] = portal.get(direction == 0 ? "from_component" : "to_component", "");
            edge["to_component"] = portal.get(direction == 0 ? "to_component" : "from_component", "");
            edge["from_grid"] = portal.get(direction == 0 ? "from_grid" : "to_grid", Vector2i());
            edge["to_grid"] = portal.get(direction == 0 ? "to_grid" : "from_grid", Vector2i());
            const String from = edge["from_component"];
            const String to = edge["to_component"];
            if (from.is_empty() || to.is_empty()) {
                continue;
            }
            Array edges = adjacency.get(from, Array());
            edges.append(edge);
            adjacency[from] = edges;
        }
    }
    return adjacency;
}
} // namespace

Dictionary NativeNavigationKernel::find_hpa(const Vector2i &from_grid,
        const Vector2i &to_grid, const Dictionary &graph_data) {
    if (!is_ready() || !graph_data.has("component_by_grid") || !graph_data.has("component_tiles")) {
        return hpa_result(Array(), "invalid");
    }
    const Dictionary component_by_grid = graph_data["component_by_grid"];
    const Dictionary component_tiles = graph_data["component_tiles"];
    const String source = component_by_grid.get(from_grid, "");
    const String goal = component_by_grid.get(to_grid, "");
    if (source.is_empty() || goal.is_empty()) {
        return hpa_result(Array(), "no_component");
    }
    if (source == goal) {
        const Array path = find_path(from_grid, to_grid);
        return hpa_result(path, path.is_empty() ? "local_path_failed" : "same_component");
    }
    const Dictionary adjacency = graph_data.has("adjacency")
        ? Dictionary(graph_data["adjacency"])
        : make_adjacency(Array(graph_data.get("portals", Array())));
    const double minimum = is_hex() ? double(graph_data.get("minimum_step_cost", -1.0)) : -1.0;
    const Dictionary goal_costs = is_hex()
        ? build_local_cost_map(to_grid, Array(component_tiles.get(goal, Array())), true)
        : Dictionary();

    std::map<String, ComponentState> states;
    states[source].g = 0.0;
    states[source].f = 0.0;
    states[source].entry = from_grid;
    states[source].open = true;
    std::vector<String> open = {source};
    bool found = false;

    while (!open.empty()) {
        size_t best = 0;
        double best_score = states[open[0]].f;
        String best_component = open[0];
        for (size_t i = 1; i < open.size(); ++i) {
            const double candidate = states[open[i]].f;
            if (candidate > best_score) {
                continue;
            }
            if (std::abs(candidate - best_score) <= 0.0001 && open[i] >= best_component) {
                continue;
            }
            best = i;
            best_score = candidate;
            best_component = open[i];
        }
        const String current = open[best];
        open.erase(open.begin() + static_cast<std::ptrdiff_t>(best));
        states[current].open = false;
        if (current == goal) {
            found = true;
            break;
        }
        if (states[current].visited) {
            continue;
        }
        states[current].visited = true;
        const Vector2i entry = states[current].entry;
        const Dictionary local_costs = is_hex()
            ? build_local_cost_map(entry, Array(component_tiles.get(current, Array())), false)
            : Dictionary();
        const Array raw_edges = adjacency.get(current, Array());
        std::vector<Dictionary> edges;
        edges.reserve(raw_edges.size());
        for (int64_t i = 0; i < raw_edges.size(); ++i) {
            edges.emplace_back(raw_edges[i]);
        }
        std::stable_sort(edges.begin(), edges.end(), [](const Dictionary &a, const Dictionary &b) {
            const String portal_a = a.get("portal_id", "");
            const String portal_b = b.get("portal_id", "");
            return portal_a == portal_b ? String(a.get("to_component", "")) < String(b.get("to_component", "")) : portal_a < portal_b;
        });
        for (const Dictionary &edge : edges) {
            const String neighbor = edge.get("to_component", "");
            if (neighbor.is_empty()) {
                continue;
            }
            const Vector2i portal = edge.get("from_grid", entry);
            const Vector2i exit = edge.get("to_grid", to_grid);
            double edge_cost = step_cost(portal, exit);
            if (std::isinf(edge_cost)) {
                edge_cost = (is_hex() ? hex_distance(portal, exit) : double(Vector2(portal).distance_to(Vector2(exit)))) + 1.0;
            }
            edge_cost = std::max(edge_cost, 0.001);
            if (is_hex()) {
                if (prune_lower_bound(states[current].g, edge_cost, states[neighbor].g,
                        entry, portal, exit, to_grid, neighbor == goal, minimum)) {
                    continue;
                }
                const double entry_cost = local_costs.get(portal, infinity);
                if (std::isinf(entry_cost)) {
                    continue;
                }
                edge_cost += entry_cost;
                if (neighbor == goal) {
                    const double exit_cost = goal_costs.get(exit, infinity);
                    if (std::isinf(exit_cost)) {
                        continue;
                    }
                    edge_cost += exit_cost;
                }
            }
            const double tentative = states[current].g + edge_cost;
            const double previous = states[neighbor].g;
            if (tentative > previous) {
                continue;
            }
            if (tentative == previous) {
                if (!is_hex()) {
                    continue;
                }
                const Vector2i old_entry = std::isfinite(states[neighbor].g) ? states[neighbor].entry : to_grid;
                if (hex_distance(exit, to_grid) >= hex_distance(old_entry, to_grid)) {
                    continue;
                }
            }
            auto &next = states[neighbor];
            next.incoming = edge;
            next.g = tentative;
            next.entry = exit;
            double heuristic = double(Vector2(exit).distance_to(Vector2(to_grid)));
            if (is_hex()) {
                heuristic = neighbor == goal ? 0.0 : hex_distance(exit, to_grid) * 0.7;
            }
            next.f = tentative + heuristic;
            if (!next.open) {
                next.open = true;
                open.push_back(neighbor);
            }
        }
    }
    if (!found) {
        return hpa_result(Array(), "no_abstract_route");
    }
    std::vector<Dictionary> route;
    String current = goal;
    while (current != source) {
        if (states[current].incoming.is_empty() || route.size() > states.size()) {
            return hpa_result(Array(), "no_abstract_route");
        }
        route.push_back(states[current].incoming);
        current = states[current].incoming.get("from_component", "");
    }
    std::reverse(route.begin(), route.end());
    Array result;
    result.append(from_grid);
    Vector2i cursor = from_grid;
    auto append_local = [&](const Vector2i &destination) {
        if (cursor == destination) {
            append_unique(result, destination);
            return true;
        }
        const Array local_path = find_path(cursor, destination);
        if (local_path.is_empty()) {
            return false;
        }
        for (int64_t i = 0; i < local_path.size(); ++i) {
            append_unique(result, Vector2i(local_path[i]));
        }
        return true;
    };
    for (const Dictionary &edge : route) {
        const Vector2i portal = edge.get("from_grid", cursor);
        const Vector2i exit = edge.get("to_grid", portal);
        if (!append_local(portal)) {
            return hpa_result(Array(), "local_path_failed");
        }
        append_unique(result, exit);
        cursor = exit;
    }
    if (!append_local(to_grid)) {
        return hpa_result(Array(), "local_path_failed");
    }
    return hpa_result(result, result.is_empty() ? "local_path_failed" : "hpa");
}
} // namespace godot
