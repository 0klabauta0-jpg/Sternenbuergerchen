# Orbit catalog and display readiness contract

This is preparation only; the live JSON and Travel/Fleet/Adapter/Root selection remain unchanged.

GRID.ORBITS and GRID.ORBIT_MARKER_IDS retain the V2 five-orbit/three-marker contract. orbits_for_version(2) returns an independent five-entry copy; version3 adds sun_orbit -> sun; unknown versions return empty. No shared mutable table is returned.

OrbitDestinationCatalog.build_v3_draft accepts the existing strict V2 input and returns the existing draft plus separate migration-only aliases. build_v3_product is explicit: it produces the same validated six-body geometry without a draft key or alias data in its returned product or definition. validate_v3_draft requires draft=true; validate_v3_product rejects any draft key and the known migration alias fields. Neither validator remaps normal commands. Both use the same geometry/range/location checks, including the pre-cast raw-coordinate/radius bounds. Product preparation does not select or write a live catalog.

StarMapCanvas reads the requested version and body_id links from owner-provided Travel.orbits/bodies; it performs display structure/marker/bounds checks and copies accepted orbit definitions. Draft-marked projections expose no orbit markers. These checks do not replace the runtime catalog validator or authorize gameplay. Captions and StarMapScreen target rows derive from these projected records. Source body order preserves the old four target rows; the valid Glut2/Polisa target is now visible, and a V3 product can show the Sun. The station body receives no separate orbit. Empty location is never a Sun surface lookup; the Sun has no surface/approach/landing action.

The same existing target_orbit_id/target_orbit_marker_id command path remains. Catalog changes rebuild the tiny target list once by signature; repeated unchanged projections retain controls. There is no runtime alias resolver or silent V2 marker migration. Full migration, Save/UI command compatibility, local entry and live product activation remain separate owner work.
