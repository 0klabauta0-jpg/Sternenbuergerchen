#pragma once

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/vector2i.hpp>

#include <array>
#include <cstdint>
#include <unordered_map>
#include <vector>

namespace godot {

// Experimental, derived navigation data only. No registry or scene references.
class NativeNavigationKernel : public RefCounted {
    GDCLASS(NativeNavigationKernel, RefCounted)

    bool ready_ = false;
    bool hex_ = false;
    int direction_count_ = 8;
    double heuristic_min_ = 0.7;
    std::vector<Vector2i> grids_;
    std::unordered_map<uint64_t, int> grid_ids_;
    std::vector<std::array<int, 8>> neighbors_;
    std::vector<std::array<double, 8>> edge_costs_;
    std::vector<uint8_t> walkable_;

    static uint64_t grid_key(const Vector2i &grid);
    int grid_id(const Vector2i &grid) const;
    int direction_index(const Vector2i &from, const Vector2i &to) const;
    double heuristic(const Vector2i &from, const Vector2i &to) const;
    void clear_snapshot();

protected:
    static void _bind_methods();

public:
    bool load_snapshot(const Dictionary &snapshot);
    Array find_path(const Vector2i &from_grid, const Vector2i &to_grid);
    Dictionary build_local_cost_map(const Vector2i &from_grid, const Array &component_grids, bool reverse_steps);
    Dictionary find_hpa(const Vector2i &from_grid, const Vector2i &to_grid, const Dictionary &graph_data);
    double step_cost(const Vector2i &from_grid, const Vector2i &to_grid) const;
    bool is_hex() const { return hex_; }
    bool is_ready() const { return ready_; }
    bool has_grid(const Vector2i &grid) const { return ready_ && grid_id(grid) >= 0; }
};

} // namespace godot
