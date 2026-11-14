#pragma once

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/variant/dictionary.hpp>

namespace godot {

// Stateless conversion of an authoritative terrain projection into directed CSR
// edges. Owns no gameplay data and performs no calls back into scripts or Nodes.
class NativeTerrainBuilder : public RefCounted {
    GDCLASS(NativeTerrainBuilder, RefCounted)

protected:
    static void _bind_methods();

public:
    Dictionary build_edges(const Dictionary &fields) const;
};

} // namespace godot
