#include "native_navigation.h"
#include "native_terrain_builder.h"
#include "native_visibility.h"
#include <godot_cpp/godot.hpp>
#include <godot_cpp/core/class_db.hpp>

using namespace godot;
static void initialize_navigation(ModuleInitializationLevel level) {
    if (level == MODULE_INITIALIZATION_LEVEL_SCENE) {
        GDREGISTER_CLASS(NativeNavigationKernel);
        GDREGISTER_CLASS(NativeRegionalSearch);
        GDREGISTER_CLASS(NativeTerrainBuilder);
        GDREGISTER_CLASS(NativeVisibilityKernel);
    }
}
static void terminate_navigation(ModuleInitializationLevel) {}
extern "C" GDExtensionBool GDE_EXPORT native_navigation_init(
    GDExtensionInterfaceGetProcAddress proc, GDExtensionClassLibraryPtr library,
    GDExtensionInitialization *initialization) {
    GDExtensionBinding::InitObject init(proc, library, initialization);
    init.register_initializer(initialize_navigation);
    init.register_terminator(terminate_navigation);
    init.set_minimum_library_initialization_level(MODULE_INITIALIZATION_LEVEL_SCENE);
    return init.init();
}
