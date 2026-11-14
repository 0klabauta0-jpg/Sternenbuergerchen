#include "native_navigation.h"

#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/packed_byte_array.hpp>
#include <godot_cpp/variant/packed_float64_array.hpp>
#include <godot_cpp/variant/packed_int32_array.hpp>

#include <algorithm>
#include <cmath>
#include <limits>

namespace godot {
namespace {
constexpr double INF_COST = std::numeric_limits<double>::infinity();
constexpr double DIAGONAL_COST = 1.41421356237;
constexpr int SQUARE_DX[8] = {1, -1, 0, 0, 1, 1, -1, -1};
constexpr int SQUARE_DY[8] = {0, 0, 1, -1, 1, -1, 1, -1};
constexpr int SQUARE_REVERSE[8] = {1, 0, 3, 2, 7, 6, 5, 4};
constexpr int HEX_DX[6] = {1, 1, 0, -1, -1, 0};
constexpr int HEX_DY[6] = {0, -1, -1, 0, 1, 1};
constexpr int HEX_REVERSE[6] = {3, 4, 5, 0, 1, 2};

// Mirrors StablePathFrontier: decrease-key retains the original open ordinal;
// reopening a popped vertex obtains a new ordinal. Snapshot validation excludes
// NaN costs, so the oracle's exceptional NaN linear mode is not needed here.
class StableFrontier {
    struct Entry { int id; double score; uint64_t ordinal; };
    std::vector<Entry> entries;
    std::vector<int> indices;
    uint64_t next_ordinal = 0;

    static bool before(const Entry &a, const Entry &b) {
        return a.score == b.score ? a.ordinal < b.ordinal : a.score < b.score;
    }
    void swap_entries(int a, int b) {
        std::swap(entries[a], entries[b]);
        indices[entries[a].id] = a;
        indices[entries[b].id] = b;
    }
    int sift_up(int index) {
        while (index > 0) {
            int parent = (index - 1) / 2;
            if (!before(entries[index], entries[parent])) break;
            swap_entries(index, parent);
            index = parent;
        }
        return index;
    }
    void sift_down(int index) {
        while (index * 2 + 1 < static_cast<int>(entries.size())) {
            int child = index * 2 + 1;
            if (child + 1 < static_cast<int>(entries.size()) && before(entries[child + 1], entries[child])) ++child;
            if (!before(entries[child], entries[index])) break;
            swap_entries(index, child);
            index = child;
        }
    }

public:
    explicit StableFrontier(size_t size) : indices(size, -1) {}
    bool empty() const { return entries.empty(); }
    void offer(int id, double score) {
        int index = indices[id];
        if (index >= 0) {
            entries[index].score = score;
            sift_down(sift_up(index));
            return;
        }
        indices[id] = static_cast<int>(entries.size());
        entries.push_back({id, score, next_ordinal++});
        sift_up(static_cast<int>(entries.size()) - 1);
    }
    int pop_lowest() {
        const int id = entries[0].id;
        const Entry last = entries.back();
        entries.pop_back();
        indices[id] = -1;
        if (!entries.empty()) {
            entries[0] = last;
            indices[last.id] = 0;
            sift_down(0);
        }
        return id;
    }
};
} // namespace

void NativeNavigationKernel::_bind_methods() {
    ClassDB::bind_method(D_METHOD("load_snapshot", "snapshot"), &NativeNavigationKernel::load_snapshot);
    ClassDB::bind_method(D_METHOD("find_path", "from_grid", "to_grid"), &NativeNavigationKernel::find_path);
    ClassDB::bind_method(D_METHOD("build_local_cost_map", "from_grid", "component_grids", "reverse_steps"), &NativeNavigationKernel::build_local_cost_map);
    ClassDB::bind_method(D_METHOD("find_hpa", "from_grid", "to_grid", "graph_data"), &NativeNavigationKernel::find_hpa);
    ClassDB::bind_method(D_METHOD("step_cost", "from_grid", "to_grid"), &NativeNavigationKernel::step_cost);
    ClassDB::bind_method(D_METHOD("is_hex"), &NativeNavigationKernel::is_hex);
    ClassDB::bind_method(D_METHOD("is_ready"), &NativeNavigationKernel::is_ready);
    ClassDB::bind_method(D_METHOD("has_grid", "grid"), &NativeNavigationKernel::has_grid);
}

uint64_t NativeNavigationKernel::grid_key(const Vector2i &grid) {
    return (static_cast<uint64_t>(static_cast<uint32_t>(grid.x)) << 32) | static_cast<uint32_t>(grid.y);
}

int NativeNavigationKernel::grid_id(const Vector2i &grid) const {
    auto found = grid_ids_.find(grid_key(grid));
    return found == grid_ids_.end() ? -1 : found->second;
}

int NativeNavigationKernel::direction_index(const Vector2i &from, const Vector2i &to) const {
    const int64_t dx = static_cast<int64_t>(to.x) - from.x;
    const int64_t dy = static_cast<int64_t>(to.y) - from.y;
    for (int d = 0; d < direction_count_; ++d) {
        if (dx == (hex_ ? HEX_DX[d] : SQUARE_DX[d]) && dy == (hex_ ? HEX_DY[d] : SQUARE_DY[d])) return d;
    }
    return -1;
}

void NativeNavigationKernel::clear_snapshot() {
    ready_ = false;
    hex_ = false;
    direction_count_ = 8;
    heuristic_min_ = 0.7;
    grids_.clear();
    grid_ids_.clear();
    neighbors_.clear();
    edge_costs_.clear();
    walkable_.clear();
}

bool NativeNavigationKernel::load_snapshot(const Dictionary &snapshot) {
    // Any rejected load invalidates the old snapshot; stale queries cannot run.
    clear_snapshot();
    if (snapshot.get("coords", Variant()).get_type() != Variant::PACKED_INT32_ARRAY ||
        snapshot.get("offsets", Variant()).get_type() != Variant::PACKED_INT32_ARRAY ||
        snapshot.get("neighbors", Variant()).get_type() != Variant::PACKED_INT32_ARRAY ||
        snapshot.get("costs", Variant()).get_type() != Variant::PACKED_FLOAT64_ARRAY ||
        snapshot.get("walkable", Variant()).get_type() != Variant::PACKED_BYTE_ARRAY ||
        snapshot.get("hex", Variant()).get_type() != Variant::BOOL) return false;
    const Variant minimum = snapshot.get("heuristic_min", Variant());
    if (minimum.get_type() != Variant::FLOAT && minimum.get_type() != Variant::INT) return false;
    heuristic_min_ = static_cast<double>(minimum);
    if (!std::isfinite(heuristic_min_) || heuristic_min_ < 0.0) return false;
    const PackedInt32Array coords = snapshot["coords"];
    const PackedInt32Array offsets = snapshot["offsets"];
    const PackedInt32Array edge_ids = snapshot["neighbors"];
    const PackedFloat64Array costs = snapshot["costs"];
    const PackedByteArray walkable = snapshot["walkable"];
    if (coords.size() % 2 != 0 || coords.size() / 2 > std::numeric_limits<int>::max()) return false;
    const int count = static_cast<int>(coords.size() / 2);
    if (offsets.size() != static_cast<int64_t>(count) + 1 || walkable.size() != count || costs.size() != edge_ids.size()) return false;
    if (offsets[0] != 0 || offsets[count] != edge_ids.size()) return false;
    hex_ = static_cast<bool>(snapshot["hex"]);
    direction_count_ = hex_ ? 6 : 8;
    grids_.resize(count);
    grid_ids_.reserve(count);
    neighbors_.resize(count);
    edge_costs_.resize(count);
    walkable_.resize(count);
    for (int i = 0; i < count; ++i) {
        if (offsets[i] < 0 || offsets[i + 1] < offsets[i] || offsets[i + 1] > edge_ids.size() || offsets[i + 1] - offsets[i] > direction_count_) {
            clear_snapshot(); return false;
        }
        grids_[i] = Vector2i(coords[i * 2], coords[i * 2 + 1]);
        if (!grid_ids_.emplace(grid_key(grids_[i]), i).second || walkable[i] > 1) {
            clear_snapshot(); return false;
        }
        walkable_[i] = walkable[i];
        neighbors_[i].fill(-1);
        edge_costs_[i].fill(INF_COST);
    }
    // Canonical direction slots preserve the script traversal order regardless
    // of hash iteration or CSR input edge order. Missing edges stay infinite.
    for (int i = 0; i < count; ++i) {
        for (int d = 0; d < direction_count_; ++d) {
            const int64_t x = static_cast<int64_t>(grids_[i].x) + (hex_ ? HEX_DX[d] : SQUARE_DX[d]);
            const int64_t y = static_cast<int64_t>(grids_[i].y) + (hex_ ? HEX_DY[d] : SQUARE_DY[d]);
            if (x < std::numeric_limits<int32_t>::min() || x > std::numeric_limits<int32_t>::max() || y < std::numeric_limits<int32_t>::min() || y > std::numeric_limits<int32_t>::max()) continue;
            neighbors_[i][d] = grid_id(Vector2i(static_cast<int32_t>(x), static_cast<int32_t>(y)));
        }
        for (int e = offsets[i]; e < offsets[i + 1]; ++e) {
            const int target = edge_ids[e];
            const double cost = costs[e];
            if (target < 0 || target >= count || !std::isfinite(cost) || cost < 0.0) {
                clear_snapshot(); return false;
            }
            const int d = direction_index(grids_[i], grids_[target]);
            if (d < 0 || std::isfinite(edge_costs_[i][d])) {
                clear_snapshot(); return false;
            }
            edge_costs_[i][d] = cost;
        }
    }
    ready_ = true;
    return true;
}

double NativeNavigationKernel::heuristic(const Vector2i &from, const Vector2i &to) const {
    const double dx = static_cast<double>(static_cast<int64_t>(to.x) - from.x);
    const double dy = static_cast<double>(static_cast<int64_t>(to.y) - from.y);
    if (hex_) return std::max(std::max(std::abs(dx), std::abs(dy)), std::abs(dx + dy)) * heuristic_min_;
    const double ax = std::abs(dx), ay = std::abs(dy);
    return (std::abs(ax - ay) + std::min(ax, ay) * DIAGONAL_COST) * heuristic_min_;
}

double NativeNavigationKernel::step_cost(const Vector2i &from_grid, const Vector2i &to_grid) const {
    if (!ready_) return INF_COST;
    const int id = grid_id(from_grid);
    const int d = direction_index(from_grid, to_grid);
    return id < 0 || d < 0 ? INF_COST : edge_costs_[id][d];
}

Array NativeNavigationKernel::find_path(const Vector2i &from_grid, const Vector2i &to_grid) {
    Array result;
    if (!ready_) return result;
    const int start = grid_id(from_grid), goal = grid_id(to_grid);
    if (start < 0 || goal < 0) return result;
    if (start == goal) { result.append(from_grid); return result; }
    std::vector<double> g_score(grids_.size(), INF_COST);
    std::vector<int> parent(grids_.size(), -1);
    StableFrontier frontier(grids_.size());
    g_score[start] = 0.0;
    frontier.offer(start, heuristic(from_grid, to_grid));
    while (!frontier.empty()) {
        const int current = frontier.pop_lowest();
        if (current == goal) {
            std::vector<int> reverse_path;
            for (int node = goal; node >= 0; node = parent[node]) reverse_path.push_back(node);
            result.resize(reverse_path.size());
            for (size_t i = 0; i < reverse_path.size(); ++i) result[i] = grids_[reverse_path[reverse_path.size() - i - 1]];
            return result;
        }
        for (int d = 0; d < direction_count_; ++d) {
            const int next = neighbors_[current][d];
            if (next < 0) continue;
            const double tentative = g_score[current] + edge_costs_[current][d];
            if (tentative >= g_score[next]) continue;
            parent[next] = current;
            g_score[next] = tentative;
            frontier.offer(next, tentative + heuristic(grids_[next], to_grid));
        }
    }
    return result;
}

Dictionary NativeNavigationKernel::build_local_cost_map(const Vector2i &from_grid, const Array &component_grids, bool reverse_steps) {
    Dictionary result;
    if (!ready_) return result;
    const int start = grid_id(from_grid);
    if (start < 0) return result;
    std::vector<uint8_t> allowed(grids_.size(), 0), settled(grids_.size(), 0), in_open(grids_.size(), 0);
    for (int64_t i = 0; i < component_grids.size(); ++i) {
        if (component_grids[i].get_type() != Variant::VECTOR2I) return result;
        const int id = grid_id(component_grids[i]);
        if (id >= 0 && walkable_[id]) allowed[id] = 1;
    }
    if (!allowed[start]) return result;
    std::vector<double> costs(grids_.size(), INF_COST);
    std::vector<int> open = {start}, discovery = {start};
    costs[start] = 0.0;
    in_open[start] = 1;
    while (!open.empty()) {
        // Retain the original linear scan tie behavior and settlement order.
        size_t best = 0;
        for (size_t i = 1; i < open.size(); ++i) if (costs[open[i]] < costs[open[best]]) best = i;
        const int current = open[best];
        open.erase(open.begin() + best);
        in_open[current] = 0;
        settled[current] = 1;
        for (int d = 0; d < direction_count_; ++d) {
            const int next = neighbors_[current][d];
            if (next < 0 || !allowed[next] || settled[next]) continue;
            const double edge = reverse_steps ? edge_costs_[next][hex_ ? HEX_REVERSE[d] : SQUARE_REVERSE[d]] : edge_costs_[current][d];
            const double candidate = costs[current] + edge;
            if (candidate >= costs[next]) continue;
            if (!std::isfinite(costs[next])) discovery.push_back(next);
            costs[next] = candidate;
            if (!in_open[next]) { open.push_back(next); in_open[next] = 1; }
        }
    }
    for (int id : discovery) result[grids_[id]] = costs[id];
    return result;
}

} // namespace godot
