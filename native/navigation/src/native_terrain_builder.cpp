#include "native_terrain_builder.h"

#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/packed_byte_array.hpp>
#include <godot_cpp/variant/packed_float64_array.hpp>
#include <godot_cpp/variant/packed_int32_array.hpp>
#include <godot_cpp/variant/vector2i.hpp>

#include <cmath>
#include <cstdint>
#include <limits>
#include <unordered_map>
#include <vector>

namespace godot {
namespace {
constexpr int HEX_DX[6] = {1, 1, 0, -1, -1, 0};
constexpr int HEX_DY[6] = {0, -1, -1, 0, 1, 1};
constexpr int SQUARE_DX[8] = {1, -1, 0, 0, 1, 1, -1, -1};
constexpr int SQUARE_DY[8] = {0, 0, 1, -1, 1, -1, 1, -1};
constexpr uint8_t EXPLICIT = 1, REGIONAL = 2, SLOPE = 4, BRIDGE = 8;

struct Cell {
    Vector2i grid;
    int height;
    int ramp;
    uint8_t traits;
    bool walkable;
    double stand_height;
    double surface_cost;
};

uint64_t key(const Vector2i &grid) {
    return (uint64_t(uint32_t(grid.x)) << 32) | uint32_t(grid.y);
}

bool hex_neighbors(const Vector2i &a, const Vector2i &b) {
    const Vector2i delta = b - a;
    for (int d = 0; d < 6; ++d) {
        if (delta.x == HEX_DX[d] && delta.y == HEX_DY[d]) return true;
    }
    return false;
}

double endpoint(const Cell &cell, const Vector2i &neighbor) {
    if (!(cell.traits & EXPLICIT) || cell.ramp == -1) return cell.height;
    if (cell.ramp < 0 || cell.ramp >= 6 || cell.height >= 16) return std::numeric_limits<double>::infinity();
    const Vector2i delta = neighbor - cell.grid;
    if (delta.x == HEX_DX[cell.ramp] && delta.y == HEX_DY[cell.ramp]) return cell.height + 1.0;
    if (delta.x == -HEX_DX[cell.ramp] && delta.y == -HEX_DY[cell.ramp]) return cell.height;
    return cell.stand_height;
}

bool allows_registry_step(const Cell &from, const Cell &to) {
    if (!from.walkable || !to.walkable) return false;
    if ((from.traits | to.traits) & EXPLICIT) {
        if (!(from.traits & EXPLICIT) || !(to.traits & EXPLICIT) || !hex_neighbors(from.grid, to.grid)) return false;
        const double a = endpoint(from, to.grid), b = endpoint(to, from.grid);
        // The accepted 0..16 domain has exact integer/half-integer endpoints.
        // Equality is identical to GDScript is_equal_approx in this domain.
        return std::isfinite(a) && std::isfinite(b) && a == b;
    }
    if (from.height == to.height) return true;
    const Cell &higher = from.height > to.height ? from : to;
    const Cell &lower = from.height > to.height ? to : from;
    if ((higher.traits & REGIONAL) && (lower.traits & REGIONAL)) {
        return higher.height - lower.height == 1 && !((higher.traits | lower.traits) & BRIDGE);
    }
    return (higher.traits & SLOPE) != 0;
}
} // namespace

void NativeTerrainBuilder::_bind_methods() {
    ClassDB::bind_method(D_METHOD("build_edges", "fields"), &NativeTerrainBuilder::build_edges);
}

Dictionary NativeTerrainBuilder::build_edges(const Dictionary &fields) const {
    if (fields.get("coords", Variant()).get_type() != Variant::PACKED_INT32_ARRAY ||
        fields.get("height", Variant()).get_type() != Variant::PACKED_INT32_ARRAY ||
        fields.get("walkable", Variant()).get_type() != Variant::PACKED_BYTE_ARRAY ||
        fields.get("traits", Variant()).get_type() != Variant::PACKED_BYTE_ARRAY ||
        fields.get("ramp_direction", Variant()).get_type() != Variant::PACKED_INT32_ARRAY ||
        fields.get("stand_height", Variant()).get_type() != Variant::PACKED_FLOAT64_ARRAY ||
        fields.get("surface_cost", Variant()).get_type() != Variant::PACKED_FLOAT64_ARRAY ||
        fields.get("hex", Variant()).get_type() != Variant::BOOL) return {};
    const PackedInt32Array coords = fields["coords"], heights = fields["height"], ramps = fields["ramp_direction"];
    const PackedByteArray walkable = fields["walkable"], traits = fields["traits"];
    const PackedFloat64Array stand = fields["stand_height"], surfaces = fields["surface_cost"];
    if (coords.size() % 2 != 0) return {};
    const int64_t count = coords.size() / 2;
    if (count > std::numeric_limits<int32_t>::max() / 8 || heights.size() != count || ramps.size() != count ||
        walkable.size() != count || traits.size() != count || stand.size() != count || surfaces.size() != count) return {};
    const bool hex = fields["hex"];
    const int directions = hex ? 6 : 8;
    std::vector<Cell> cells;
    cells.reserve(size_t(count));
    std::unordered_map<uint64_t, int> ids;
    ids.reserve(size_t(count));
    for (int i = 0; i < count; ++i) {
        const Vector2i grid(coords[i * 2], coords[i * 2 + 1]);
        if (std::abs(int64_t(grid.x)) > 1000000 || std::abs(int64_t(grid.y)) > 1000000 ||
            heights[i] < 0 || heights[i] > 16 || ramps[i] < -1 || ramps[i] >= 6 ||
            walkable[i] > 1 || traits[i] > 15 || !std::isfinite(surfaces[i]) || surfaces[i] <= 0.0 || surfaces[i] > 1e12) return {};
        const double expected_stand = heights[i] + (((traits[i] & EXPLICIT) && ramps[i] >= 0 && heights[i] < 16) ? 0.5 : 0.0);
        if (stand[i] != expected_stand || !ids.emplace(key(grid), i).second) return {};
        cells.push_back({grid, heights[i], ramps[i], traits[i], walkable[i] != 0, stand[i], surfaces[i]});
    }
    auto id_at = [&ids](const Vector2i &grid) -> int {
        auto found = ids.find(key(grid));
        return found == ids.end() ? -1 : found->second;
    };
    PackedInt32Array offsets, neighbors;
    PackedFloat64Array costs;
    offsets.resize(count + 1);
    std::vector<int32_t> edge_ids;
    std::vector<double> edge_costs;
    edge_ids.reserve(size_t(count) * directions);
    edge_costs.reserve(size_t(count) * directions);
    for (int i = 0; i < count; ++i) {
        offsets.set(i, int32_t(edge_ids.size()));
        const Cell &from = cells[i];
        for (int d = 0; d < directions; ++d) {
            const int dx = hex ? HEX_DX[d] : SQUARE_DX[d], dy = hex ? HEX_DY[d] : SQUARE_DY[d];
            const int target = id_at(from.grid + Vector2i(dx, dy));
            if (target < 0) continue;
            if (!hex && dx != 0 && dy != 0) {
                const int side_x = id_at(from.grid + Vector2i(dx, 0));
                const int side_y = id_at(from.grid + Vector2i(0, dy));
                if (side_x < 0 || side_y < 0 || !allows_registry_step(from, cells[side_x]) || !allows_registry_step(from, cells[side_y])) continue;
            }
            const Cell &to = cells[target];
            if (!allows_registry_step(from, to)) continue;
            double cost = to.surface_cost;
            const double height_difference = std::abs(to.stand_height - from.stand_height);
            if (height_difference > 0.0) cost += height_difference;
            edge_ids.push_back(target);
            edge_costs.push_back(cost);
        }
    }
    offsets.set(count, int32_t(edge_ids.size()));
    neighbors.resize(edge_ids.size());
    costs.resize(edge_costs.size());
    for (size_t i = 0; i < edge_ids.size(); ++i) {
        neighbors.set(i, edge_ids[i]);
        costs.set(i, edge_costs[i]);
    }
    Dictionary result;
    result["offsets"] = offsets;
    result["neighbors"] = neighbors;
    result["costs"] = costs;
    return result;
}
} // namespace godot
