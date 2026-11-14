#include "native_visibility.h"

#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/math.hpp>
#include <godot_cpp/variant/vector2.hpp>

#include <algorithm>
#include <cmath>
#include <cstdint>

namespace godot {
namespace {
// Mirrors HexGrid.round_axial: scalar operations are doubles, Vector2 is real_t.
Vector2i rounded_axial(const Vector2 &axial) {
    const double x = axial.x, z = axial.y, y = -x - z;
    int64_t rx = int64_t(Math::round(x)), ry = int64_t(Math::round(y)), rz = int64_t(Math::round(z));
    const double ex = std::abs(double(rx) - x), ey = std::abs(double(ry) - y), ez = std::abs(double(rz) - z);
    if (ex > ey && ex > ez) rx = -ry - rz;
    else if (ey > ez) ry = -rx - rz;
    else rz = -rx - ry;
    return Vector2i(int32_t(rx), int32_t(rz));
}
} // namespace

void NativeVisibilityKernel::_bind_methods() {
    ClassDB::bind_method(D_METHOD("build_hex_line", "source", "target"), &NativeVisibilityKernel::build_hex_line);
}

TypedArray<Vector2i> NativeVisibilityKernel::build_hex_line(const Vector2i &source, const Vector2i &target) const {
    TypedArray<Vector2i> result;
    // Unsupported coordinates return an empty result, selecting the unchanged
    // GDScript path. Bound native allocation and avoid int32 subtraction overflow.
    constexpr int64_t COORDINATE_LIMIT = 1000000;
    constexpr int64_t STEP_LIMIT = 65536;
    if (std::abs(int64_t(source.x)) > COORDINATE_LIMIT || std::abs(int64_t(source.y)) > COORDINATE_LIMIT ||
            std::abs(int64_t(target.x)) > COORDINATE_LIMIT || std::abs(int64_t(target.y)) > COORDINATE_LIMIT) return result;
    const int64_t dx = int64_t(source.x) - target.x, dy = int64_t(source.y) - target.y;
    const int64_t steps = std::max({std::abs(dx), std::abs(dy), std::abs(dx + dy)});
    if (steps > STEP_LIMIT) return result;
    if (steps == 0) {
        result.append(source);
        return result;
    }
    const bool reversed = source.x > target.x || (source.x == target.x && source.y > target.y);
    const Vector2 first(reversed ? target : source), last(reversed ? source : target);
    const Vector2 nudge(0.000001, 0.000001);
    result.resize(steps + 1);
    int64_t count = 0;
    Vector2i previous;
    for (int64_t index = 0; index <= steps; ++index) {
        // Use the same Vector2 lerp (float-weight rounding included), canonical
        // endpoints and nudge as HexGrid.line; do not algebraically rearrange.
        const Vector2 axial = first.lerp(last, real_t(double(index) / double(steps))) + nudge;
        const Vector2i cell = rounded_axial(axial);
        if (count == 0 || cell != previous) {
            result[count++] = cell;
            previous = cell;
        }
    }
    if (count != result.size()) result.resize(count);
    if (reversed) result.reverse();
    return result;
}

} // namespace godot
