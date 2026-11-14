#include "native_navigation.h"

#include <godot_cpp/core/class_db.hpp>

#include <algorithm>
#include <cmath>
#include <limits>

namespace godot {
namespace {
constexpr double INF_COST = std::numeric_limits<double>::infinity();

int64_t regional_distance(const Vector2i &a, const Vector2i &b) {
    const int64_t dx = int64_t(a.x) - b.x;
    const int64_t dy = int64_t(a.y) - b.y;
    return std::max({std::abs(dx), std::abs(dy), std::abs(dx + dy)});
}
} // namespace

Ref<NativeRegionalSearch> NativeNavigationKernel::create_regional_search(const Vector2i &from_grid, const Vector2i &to_grid, const Dictionary &options) {
    Ref<NativeRegionalSearch> result;
    const int start = grid_id(from_grid);
    QueryOptions query;
    if (!ready_ || !dynamic_costs_ || !hex_ || start < 0 ||
        std::abs(int64_t(to_grid.x)) > 1000000 || std::abs(int64_t(to_grid.y)) > 1000000 ||
        !parse_query_options(options, query)) return result;
    result.instantiate();
    result->kernel_ = Ref<NativeNavigationKernel>(this);
    result->snapshot_generation_ = snapshot_generation_;
    result->query_ = std::move(query);
    result->goal_ = to_grid;
    result->nearest_ = start;
    result->nearest_distance_ = regional_distance(from_grid, to_grid);
    // RegionalHexSearch's lower bound differs from the ordinary hex A* oracle.
    result->minimum_cost_ = result->query_.cover_aware ? std::max(0.05, 0.7 - result->query_.cover_weight) : 0.7;
    result->costs_[start] = 0.0;
    result->offer(start, double(result->nearest_distance_) * result->minimum_cost_);
    return result;
}

void NativeRegionalSearch::_bind_methods() {
    ClassDB::bind_method(D_METHOD("advance", "expansion_limit"), &NativeRegionalSearch::advance);
}

bool NativeRegionalSearch::before(const Entry &a, const Entry &b) {
    return a.score == b.score ? a.ordinal < b.ordinal : a.score < b.score;
}

void NativeRegionalSearch::swap_entries(int a, int b) {
    std::swap(frontier_[a], frontier_[b]);
    indices_[frontier_[a].id] = a;
    indices_[frontier_[b].id] = b;
}

int NativeRegionalSearch::sift_up(int index) {
    while (index > 0) {
        const int parent = (index - 1) / 2;
        if (!before(frontier_[index], frontier_[parent])) break;
        swap_entries(index, parent);
        index = parent;
    }
    return index;
}

void NativeRegionalSearch::sift_down(int index) {
    while (index * 2 + 1 < int(frontier_.size())) {
        int child = index * 2 + 1;
        if (child + 1 < int(frontier_.size()) && before(frontier_[child + 1], frontier_[child])) ++child;
        if (!before(frontier_[child], frontier_[index])) break;
        swap_entries(index, child);
        index = child;
    }
}

void NativeRegionalSearch::offer(int id, double score) {
    const auto found = indices_.find(id);
    if (found != indices_.end()) {
        const int index = found->second;
        frontier_[index].score = score;
        sift_down(sift_up(index));
        return;
    }
    indices_[id] = int(frontier_.size());
    frontier_.push_back({id, score, next_ordinal_++});
    sift_up(int(frontier_.size()) - 1);
}

int NativeRegionalSearch::pop_lowest() {
    const int id = frontier_[0].id;
    const Entry last = frontier_.back();
    frontier_.pop_back();
    indices_.erase(id);
    if (!frontier_.empty()) {
        frontier_[0] = last;
        indices_[last.id] = 0;
        sift_down(0);
    }
    return id;
}

double NativeRegionalSearch::edge_cost(int from_id, int direction) {
    const uint64_t key = uint64_t(from_id) * 8 + uint64_t(direction);
    const auto cached = edges_.find(key);
    if (cached != edges_.end()) return cached->second;
    const int target = kernel_->neighbors_[from_id][direction];
    if (target < 0 || !std::isfinite(kernel_->edge_costs_[from_id][direction]) ||
        query_.blocked.count(NativeNavigationKernel::grid_key(kernel_->grids_[target]))) {
        edges_[key] = INF_COST;
        return INF_COST;
    }
    auto components = targets_.find(target);
    if (components == targets_.end()) components = targets_.emplace(target, kernel_->compute_target_costs(target, query_)).first;
    const double cost = kernel_->cost_with_components(from_id, direction, query_, components->second);
    edges_[key] = cost;
    return cost;
}

Dictionary NativeRegionalSearch::result(int64_t used) const {
    Dictionary result;
    result["used"] = used;
    result["finished"] = finished_;
    result["invalidated"] = invalidated_;
    result["expanded_count"] = expanded_count_;
    result["path"] = path_.duplicate(false);
    result["target_cost_compute_count"] = int64_t(targets_.size());
    result["edge_cost_compute_count"] = int64_t(edges_.size());
    return result;
}

Dictionary NativeRegionalSearch::advance(int64_t expansion_limit) {
    if (kernel_.is_null() || !kernel_->ready_ || kernel_->snapshot_generation_ != snapshot_generation_) {
        invalidated_ = true;
        finished_ = true;
        path_.clear();
        return result(0);
    }
    if (finished_) return result(0);
    int64_t used = 0;
    while (used < expansion_limit && !frontier_.empty()) {
        const int current = pop_lowest();
        ++used;
        const int64_t distance = regional_distance(kernel_->grids_[current], goal_);
        if (distance < nearest_distance_) {
            nearest_distance_ = distance;
            nearest_ = current;
        }
        if (kernel_->grids_[current] == goal_) break;
        const double current_cost = costs_.at(current);
        // Snapshot direction slots are exactly HexGrid.DIRECTIONS order.
        for (int direction = 0; direction < 6; ++direction) {
            const int neighbor = kernel_->neighbors_[current][direction];
            if (neighbor < 0) continue;
            const auto known = costs_.find(neighbor);
            const double known_cost = known == costs_.end() ? INF_COST : known->second;
            if (current_cost + minimum_cost_ >= known_cost) continue;
            const double next_cost = current_cost + edge_cost(current, direction);
            if (next_cost >= known_cost) continue;
            costs_[neighbor] = next_cost;
            parents_[neighbor] = current;
            offer(neighbor, next_cost + double(regional_distance(kernel_->grids_[neighbor], goal_)) * minimum_cost_);
        }
    }
    expanded_count_ += used;
    finished_ = nearest_distance_ == 0 || frontier_.empty();
    if (finished_) {
        std::vector<int> reverse_path;
        int current = nearest_;
        for (;;) {
            reverse_path.push_back(current);
            const auto parent = parents_.find(current);
            if (parent == parents_.end()) break;
            current = parent->second;
        }
        path_.resize(reverse_path.size());
        for (size_t i = 0; i < reverse_path.size(); ++i) path_[i] = kernel_->grids_[reverse_path[reverse_path.size() - i - 1]];
    }
    return result(used);
}

} // namespace godot
