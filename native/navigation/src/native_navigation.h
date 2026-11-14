#pragma once

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/vector2i.hpp>

#include <array>
#include <cstdint>
#include <unordered_map>
#include <unordered_set>
#include <vector>

namespace godot {

class NativeRegionalSearch;

// Derived navigation data only. No registry or scene references.
class NativeNavigationKernel : public RefCounted {
    GDCLASS(NativeNavigationKernel, RefCounted)
    friend class NativeRegionalSearch;

    uint64_t snapshot_generation_ = 0;
    bool ready_ = false;
    bool hex_ = false;
    int direction_count_ = 8;
    double heuristic_min_ = 0.7;
    std::vector<Vector2i> grids_;
    std::unordered_map<uint64_t, int> grid_ids_;
    std::vector<std::array<int, 8>> neighbors_;
    std::vector<std::array<double, 8>> edge_costs_;
    std::vector<uint8_t> walkable_;

    struct QueryOptions {
        bool cover_aware = false;
        bool corridor_enabled = false;
        bool lane_enabled = false;
        bool has_corridor_from = false;
        bool has_corridor_to = false;
        Vector2i corridor_from;
        Vector2i corridor_to;
        double exposure_weight = 0.0;
        double cover_weight = 0.0;
        double exposure_max_distance = 8.0;
        double corridor_weight = 0.0;
        double corridor_half_width = 0.0;
        double lane_weight = 0.0;
        double lane_offset = 0.0;
        double clearance_weight = 0.0;
        int clearance_radius = 1;
        std::vector<Vector2i> hazards;
        std::unordered_map<uint64_t, double> exposures;
        std::unordered_set<uint64_t> blocked;
    } query_;
    struct TargetCosts {
        uint64_t generation = 0;
        double exposure = 0.0;
        double corridor = 0.0;
        double lane = 0.0;
        double clearance = 0.0;
    };
    bool dynamic_costs_ = false;
    bool query_ready_ = false;
    uint64_t query_generation_ = 0;
    uint64_t target_cost_compute_count_ = 0;
    uint64_t edge_cost_compute_count_ = 0;
    std::vector<double> cover_;
    std::vector<uint8_t> blocks_los_;
    std::vector<int32_t> height_, object_height_;
    std::vector<TargetCosts> target_costs_;
    std::vector<std::array<uint64_t, 8>> edge_generations_;
    std::vector<std::array<double, 8>> query_edge_costs_;

    static uint64_t grid_key(const Vector2i &grid);
    int grid_id(const Vector2i &grid) const;
    int direction_index(const Vector2i &from, const Vector2i &to) const;
    double heuristic(const Vector2i &from, const Vector2i &to) const;
    void clear_snapshot();
    double cost_for_edge(int from_id, int direction);
    bool parse_query_options(const Dictionary &options, QueryOptions &next) const;
    double cost_with_components(int from_id, int direction, const QueryOptions &query, const TargetCosts &components) const;
    TargetCosts compute_target_costs(int target_id, const QueryOptions &query) const;
    const TargetCosts &target_costs(int target_id);
    double exposure_score(int target_id, const QueryOptions &query) const;
    bool line_of_sight(const Vector2i &source, const Vector2i &target) const;
    double signed_line_distance(const Vector2i &grid, const QueryOptions &query) const;
    double clearance_penalty(int target_id, const QueryOptions &query) const;

protected:
    static void _bind_methods();

public:
    bool load_snapshot(const Dictionary &snapshot);
    bool load_terrain(const Dictionary &snapshot);
    bool begin_query(const Dictionary &options);
    Dictionary get_query_debug() const;
    Ref<NativeRegionalSearch> create_regional_search(const Vector2i &from_grid, const Vector2i &to_grid, const Dictionary &options);
    Array find_path(const Vector2i &from_grid, const Vector2i &to_grid);
    Dictionary build_local_cost_map(const Vector2i &from_grid, const Array &component_grids, bool reverse_steps);
    Dictionary find_hpa(const Vector2i &from_grid, const Vector2i &to_grid, const Dictionary &graph_data);
    double step_cost(const Vector2i &from_grid, const Vector2i &to_grid);
    bool is_hex() const { return hex_; }
    bool is_ready() const { return ready_ && (!dynamic_costs_ || query_ready_); }
    bool has_grid(const Vector2i &grid) const { return is_ready() && grid_id(grid) >= 0; }
};

// One accepted regional query. Sparse search/cost state, shared terrain owner.
// Registry revision changes are checked by the script owner; snapshot generation
// also rejects direct stale native jobs without exposing a previous map's path.
class NativeRegionalSearch : public RefCounted {
    GDCLASS(NativeRegionalSearch, RefCounted)
    friend class NativeNavigationKernel;
    Ref<NativeNavigationKernel> kernel_;
    NativeNavigationKernel::QueryOptions query_;
    uint64_t snapshot_generation_ = 0;
    struct Entry { int id; double score; uint64_t ordinal; };
    std::vector<Entry> frontier_;
    std::unordered_map<int, int> indices_;
    std::unordered_map<int, double> costs_;
    std::unordered_map<int, int> parents_;
    std::unordered_map<int, NativeNavigationKernel::TargetCosts> targets_;
    std::unordered_map<uint64_t, double> edges_;
    uint64_t next_ordinal_ = 0;
    Vector2i goal_;
    int nearest_ = -1;
    int64_t nearest_distance_ = 0;
    int64_t expanded_count_ = 0;
    double minimum_cost_ = 0.7;
    bool finished_ = false;
    bool invalidated_ = false;
    Array path_;
    static bool before(const Entry &a, const Entry &b);
    void swap_entries(int a, int b);
    int sift_up(int index);
    void sift_down(int index);
    void offer(int id, double score);
    int pop_lowest();
    double edge_cost(int from_id, int direction);
    Dictionary result(int64_t used) const;

protected:
    static void _bind_methods();

public:
    Dictionary advance(int64_t expansion_limit);
};

} // namespace godot
