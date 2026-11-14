#include "native_navigation.h"

#include <godot_cpp/core/math.hpp>
#include <godot_cpp/variant/packed_byte_array.hpp>
#include <godot_cpp/variant/packed_float64_array.hpp>
#include <godot_cpp/variant/packed_int32_array.hpp>
#include <godot_cpp/variant/vector2.hpp>

#include <algorithm>
#include <cmath>
#include <limits>

namespace godot {
namespace {
constexpr double INF_COST = std::numeric_limits<double>::infinity();
constexpr double DIAGONAL_COST = 1.41421356237;
constexpr double SQRT_THREE = 1.7320508075688772;
constexpr int COORDINATE_LIMIT = 1000000;
constexpr double OPTION_LIMIT = 1.0e12;

bool bounded_grid(const Vector2i &grid) {
    return std::abs(int64_t(grid.x)) <= COORDINATE_LIMIT && std::abs(int64_t(grid.y)) <= COORDINATE_LIMIT;
}

int64_t hex_distance(const Vector2i &a, const Vector2i &b) {
    const int64_t dx = int64_t(a.x) - b.x;
    const int64_t dy = int64_t(a.y) - b.y;
    return std::max({std::abs(dx), std::abs(dy), std::abs(dx + dy)});
}

Vector2 axial_to_plane(const Vector2i &grid) {
    const Vector2 axial(grid);
    // GDScript scalar expressions use doubles; only Vector2 construction rounds.
    return Vector2(double(axial.x) + 0.5 * double(axial.y), 0.5 * SQRT_THREE * double(axial.y));
}

Vector2i round_axial(const Vector2 &axial) {
    const double x = axial.x, z = axial.y, y = -x - z;
    int64_t rx = int64_t(Math::round(x)), ry = int64_t(Math::round(y)), rz = int64_t(Math::round(z));
    const double ex = std::abs(double(rx) - x), ey = std::abs(double(ry) - y), ez = std::abs(double(rz) - z);
    if (ex > ey && ex > ez) rx = -ry - rz;
    else if (ey > ez) ry = -rx - rz;
    else rz = -rx - ry;
    return Vector2i(int32_t(rx), int32_t(rz));
}
} // namespace

bool NativeNavigationKernel::load_terrain(const Dictionary &snapshot) {
    Dictionary csr = snapshot.duplicate(false);
    csr["heuristic_min"] = 0.7;
    if (!load_snapshot(csr)) return false;
    auto reject = [&]() { clear_snapshot(); return false; };
    if (snapshot.get("cover", Variant()).get_type() != Variant::PACKED_FLOAT64_ARRAY ||
        snapshot.get("blocks_los", Variant()).get_type() != Variant::PACKED_BYTE_ARRAY ||
        snapshot.get("height", Variant()).get_type() != Variant::PACKED_INT32_ARRAY ||
        snapshot.get("object_height", Variant()).get_type() != Variant::PACKED_INT32_ARRAY) return reject();
    const PackedFloat64Array cover = snapshot["cover"];
    const PackedByteArray blocks_los = snapshot["blocks_los"];
    const PackedInt32Array height = snapshot["height"];
    const PackedInt32Array object_height = snapshot["object_height"];
    const size_t count = grids_.size();
    if (cover.size() != count || blocks_los.size() != count || height.size() != count || object_height.size() != count) return reject();
    cover_.resize(count);
    blocks_los_.resize(count);
    height_.resize(count);
    object_height_.resize(count);
    for (size_t i = 0; i < count; ++i) {
        if (!bounded_grid(grids_[i]) || !std::isfinite(cover[i]) || cover[i] < 0.0 || cover[i] > 1.0 || blocks_los[i] > 1) return reject();
        cover_[i] = cover[i];
        blocks_los_[i] = blocks_los[i];
        height_[i] = height[i];
        object_height_[i] = object_height[i];
    }
    target_costs_.resize(count);
    edge_generations_.resize(count);
    query_edge_costs_.resize(count);
    for (auto &generations : edge_generations_) generations.fill(0);
    dynamic_costs_ = true;
    query_ready_ = false;
    return true;
}

bool NativeNavigationKernel::parse_query_options(const Dictionary &options, QueryOptions &next) const {
    if (options.get("diagnostics", Variant()).get_type() == Variant::DICTIONARY) return false;
    auto number = [&](const char *name, double fallback, double &value) {
        const Variant input = options.get(name, fallback);
        if (input.get_type() != Variant::INT && input.get_type() != Variant::FLOAT) return false;
        value = double(input);
        return std::isfinite(value) && std::abs(value) <= OPTION_LIMIT;
    };
    auto flag = [&](const char *name, bool &value) {
        const Variant input = options.get(name, false);
        if (input.get_type() != Variant::BOOL) return false;
        value = bool(input);
        return true;
    };
    if (!flag("cover_aware_enabled", next.cover_aware) || !flag("corridor_enabled", next.corridor_enabled) || !flag("lane_enabled", next.lane_enabled) ||
        !number("exposure_weight", 0.0, next.exposure_weight) || !number("cover_weight", 0.0, next.cover_weight) ||
        !number("exposure_max_grid_distance", 8.0, next.exposure_max_distance) || !number("corridor_weight", 0.0, next.corridor_weight) ||
        !number("corridor_half_width_grid", 0.0, next.corridor_half_width) || !number("lane_weight", 0.0, next.lane_weight) ||
        !number("lane_offset_grid", 0.0, next.lane_offset) || !number("blocker_clearance_weight", 0.0, next.clearance_weight)) return false;
    double radius;
    if (!number("blocker_clearance_radius", 1.0, radius) || radius > 64.0) return false;
    next.clearance_radius = radius < 1.0 ? 1 : int(radius);
    next.exposure_weight = std::max(next.exposure_weight, 0.0);
    next.cover_weight = std::max(next.cover_weight, 0.0);
    next.exposure_max_distance = std::max(next.exposure_max_distance, 0.001);
    next.corridor_weight = std::max(next.corridor_weight, 0.0);
    next.corridor_half_width = std::max(next.corridor_half_width, 0.0);
    next.lane_weight = std::max(next.lane_weight, 0.0);
    next.clearance_weight = std::max(next.clearance_weight, 0.0);
    auto endpoint = [&](const char *name, bool &present, Vector2i &value) {
        present = options.has(name);
        if (!present) return true;
        const Variant input = options[name];
        if (input.get_type() != Variant::VECTOR2I) return false;
        value = input;
        return bounded_grid(value);
    };
    if (!endpoint("corridor_from_grid", next.has_corridor_from, next.corridor_from) ||
        !endpoint("corridor_to_grid", next.has_corridor_to, next.corridor_to)) return false;
    const Variant hazard_input = options.get("hazard_grids", Array());
    const Variant exposure_input = options.get("exposure_by_grid", Dictionary());
    if (hazard_input.get_type() != Variant::ARRAY || exposure_input.get_type() != Variant::DICTIONARY) return false;
    const Array hazards = hazard_input;
    for (int64_t i = 0; i < hazards.size(); ++i) {
        if (hazards[i].get_type() != Variant::VECTOR2I) return false;
        const Vector2i grid = hazards[i];
        if (!bounded_grid(grid)) return false;
        next.hazards.push_back(grid);
    }
    const Dictionary exposures = exposure_input;
    const Array exposure_keys = exposures.keys();
    for (int64_t i = 0; i < exposure_keys.size(); ++i) {
        const Variant key = exposure_keys[i];
        const Variant value = exposures[key];
        if (key.get_type() != Variant::VECTOR2I || (value.get_type() != Variant::INT && value.get_type() != Variant::FLOAT)) return false;
        const Vector2i grid = key;
        const double score = value;
        if (!bounded_grid(grid) || !std::isfinite(score)) return false;
        next.exposures[grid_key(grid)] = std::clamp(score, 0.0, 1.0);
    }
    const Variant blocked_input = options.get("blocked_grids", Dictionary());
    if (blocked_input.get_type() != Variant::DICTIONARY) return false;
    const Dictionary blocked = blocked_input;
    const Array blocked_keys = blocked.keys();
    for (int64_t i = 0; i < blocked_keys.size(); ++i) {
        if (blocked_keys[i].get_type() != Variant::VECTOR2I) return false;
        const Vector2i grid = blocked_keys[i];
        if (!bounded_grid(grid)) return false;
        // Presence blocks, even when the dictionary value is false.
        next.blocked.insert(grid_key(grid));
    }
    return true;
}

bool NativeNavigationKernel::begin_query(const Dictionary &options) {
    // Rejecting a query keeps its immutable terrain, but never exposes old costs.
    query_ready_ = false;
    target_cost_compute_count_ = 0;
    edge_cost_compute_count_ = 0;
    QueryOptions next;
    if (!ready_ || !dynamic_costs_ || !parse_query_options(options, next)) return false;
    query_ = std::move(next);
    // The ordinary path is O(options), with no map-wide reset or cost rebuild.
    if (++query_generation_ == 0) {
        for (auto &target : target_costs_) target.generation = 0;
        for (auto &generations : edge_generations_) generations.fill(0);
        query_generation_ = 1;
    }
    heuristic_min_ = query_.cover_aware ? (hex_ ? 0.05 : std::max(0.05, 0.7 - query_.cover_weight)) : 0.7;
    query_ready_ = true;
    return true;
}

Dictionary NativeNavigationKernel::get_query_debug() const {
    Dictionary debug;
    debug["target_cost_compute_count"] = int64_t(target_cost_compute_count_);
    debug["edge_cost_compute_count"] = int64_t(edge_cost_compute_count_);
    debug["query_generation"] = int64_t(query_generation_);
    debug["query_ready"] = query_ready_;
    debug["terrain_cell_count"] = int64_t(grids_.size());
    return debug;
}

double NativeNavigationKernel::cost_with_components(int from_id, int direction, const QueryOptions &query, const TargetCosts &components) const {
    const int target_id = neighbors_[from_id][direction];
    double cost = edge_costs_[from_id][direction];
    if (query.cover_aware) cost = std::max(cost + query.exposure_weight * components.exposure - query.cover_weight * cover_[target_id], 0.05);
    cost += components.corridor;
    cost += components.lane;
    cost += components.clearance;
    if (!hex_ && direction >= 4) cost *= DIAGONAL_COST;
    return cost;
}

double NativeNavigationKernel::cost_for_edge(int from_id, int direction) {
    const double base = edge_costs_[from_id][direction];
    if (!dynamic_costs_) return base;
    if (!query_ready_ || !std::isfinite(base)) return INF_COST;
    if (edge_generations_[from_id][direction] == query_generation_) return query_edge_costs_[from_id][direction];
    const int target_id = neighbors_[from_id][direction];
    if (target_id < 0 || query_.blocked.count(grid_key(grids_[target_id]))) return INF_COST;
    const double cost = cost_with_components(from_id, direction, query_, target_costs(target_id));
    query_edge_costs_[from_id][direction] = cost;
    edge_generations_[from_id][direction] = query_generation_;
    ++edge_cost_compute_count_;
    return cost;
}

NativeNavigationKernel::TargetCosts NativeNavigationKernel::compute_target_costs(int target_id, const QueryOptions &query) const {
    TargetCosts costs;
    costs.exposure = exposure_score(target_id, query);
    if ((query.corridor_enabled && query.corridor_weight > 0.0) || (query.lane_enabled && query.lane_weight > 0.0)) {
        const double distance = signed_line_distance(grids_[target_id], query);
        if (query.corridor_enabled && query.corridor_weight > 0.0 && std::abs(distance) > query.corridor_half_width) {
            costs.corridor = (std::abs(distance) - query.corridor_half_width) * query.corridor_weight;
        }
        if (query.lane_enabled && query.lane_weight > 0.0) costs.lane = std::abs(distance - query.lane_offset) * query.lane_weight * 0.35;
    }
    costs.clearance = clearance_penalty(target_id, query);
    return costs;
}

const NativeNavigationKernel::TargetCosts &NativeNavigationKernel::target_costs(int target_id) {
    TargetCosts &costs = target_costs_[target_id];
    if (costs.generation == query_generation_) return costs;
    costs = compute_target_costs(target_id, query_);
    costs.generation = query_generation_;
    ++target_cost_compute_count_;
    return costs;
}

double NativeNavigationKernel::signed_line_distance(const Vector2i &grid, const QueryOptions &query) const {
    const Vector2i from = query.has_corridor_from ? query.corridor_from : grid;
    const Vector2i to = query.has_corridor_to ? query.corridor_to : grid;
    const Vector2 from_value = hex_ ? axial_to_plane(from) : Vector2(from);
    const Vector2 to_value = hex_ ? axial_to_plane(to) : Vector2(to);
    const Vector2 point_value = hex_ ? axial_to_plane(grid) : Vector2(grid);
    const Vector2 line = to_value - from_value;
    const double length = line.length();
    if (length <= 0.001) return 0.0;
    const Vector2 delta = point_value - from_value;
    return double(line.cross(delta)) / length;
}

double NativeNavigationKernel::clearance_penalty(int target_id, const QueryOptions &query) const {
    if (query.clearance_weight <= 0.0) return 0.0;
    const Vector2i grid = grids_[target_id];
    const int radius = query.clearance_radius;
    double score = 0.0;
    int samples = 0;
    for (int dx = -radius; dx <= radius; ++dx) {
        for (int dy = -radius; dy <= radius; ++dy) {
            if (dx == 0 && dy == 0) continue;
            if (hex_ && hex_distance(Vector2i(), Vector2i(dx, dy)) > radius) continue;
            ++samples;
            const int id = grid_id(grid + Vector2i(dx, dy));
            if (id < 0 || !walkable_[id]) score += 1.0;
            else if (blocks_los_[id]) score += 0.45;
        }
    }
    if (samples <= 0) return 0.0;
    return std::clamp(score / double(samples), 0.0, 1.0) * query.clearance_weight * 0.4;
}

double NativeNavigationKernel::exposure_score(int target_id, const QueryOptions &query) const {
    if (!query.cover_aware) return 0.0;
    const Vector2i grid = grids_[target_id];
    const auto override = query.exposures.find(grid_key(grid));
    if (override != query.exposures.end()) return override->second;
    double exposure = 0.0;
    for (const Vector2i &hazard : query.hazards) {
        const double distance = hex_ ? double(hex_distance(grid, hazard)) : double(std::max(std::abs(int64_t(grid.x) - hazard.x), std::abs(int64_t(grid.y) - hazard.y)));
        if (distance > query.exposure_max_distance || !line_of_sight(hazard, grid)) continue;
        const double contribution = 1.0 - std::clamp(distance / query.exposure_max_distance, 0.0, 1.0);
        exposure = std::max(exposure, contribution);
    }
    return std::clamp(exposure, 0.0, 1.0);
}

bool NativeNavigationKernel::line_of_sight(const Vector2i &source, const Vector2i &target) const {
    const int source_id = grid_id(source), target_id = grid_id(target);
    const int64_t source_height = source_id < 0 ? 0 : height_[source_id];
    const int64_t target_height = target_id < 0 ? 0 : height_[target_id];
    std::vector<Vector2i> line;
    if (hex_) {
        Vector2i first = source, last = target;
        if (first.x > last.x || (first.x == last.x && first.y > last.y)) std::swap(first, last);
        const int64_t steps = hex_distance(first, last);
        if (steps == 0) return true;
        const Vector2 nudge(0.000001, 0.000001);
        for (int64_t step = 0; step <= steps; ++step) {
            const Vector2 axial = Vector2(first).lerp(Vector2(last), real_t(double(step) / double(steps))) + nudge;
            const Vector2i rounded = round_axial(axial);
            if (line.empty() || rounded != line.back()) line.push_back(rounded);
        }
        // LOS only examines interior cells with symmetric endpoint height tests.
        // Canonical forward order therefore exactly matches reversed HexGrid.line.
    } else {
        const int64_t steps = std::max(std::abs(int64_t(target.x) - source.x), std::abs(int64_t(target.y) - source.y));
        for (int64_t step = 0; step <= steps; ++step) {
            const double t = double(step) / double(std::max(steps, int64_t(1)));
            line.emplace_back(int32_t(Math::round(Math::lerp(double(source.x), double(target.x), t))), int32_t(Math::round(Math::lerp(double(source.y), double(target.y), t))));
        }
    }
    for (size_t i = 1; i + 1 < line.size(); ++i) {
        const int id = grid_id(line[i]);
        if (id < 0 || !blocks_los_[id]) continue;
        const int64_t blocker_height = int64_t(height_[id]) + object_height_[id];
        if (blocker_height >= source_height && blocker_height >= target_height) return false;
    }
    return true;
}

} // namespace godot
