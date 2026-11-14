#pragma once

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/variant/typed_array.hpp>
#include <godot_cpp/variant/vector2i.hpp>

namespace godot {

// Stateless ray geometry only. Reads no terrain or objects and owns no visibility.
class NativeVisibilityKernel : public RefCounted {
    GDCLASS(NativeVisibilityKernel, RefCounted)

protected:
    static void _bind_methods();

public:
    TypedArray<Vector2i> build_hex_line(const Vector2i &source, const Vector2i &target) const;
};

} // namespace godot
