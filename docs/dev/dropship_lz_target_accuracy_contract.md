# Dropship LZ Target Accuracy Contract

Status: implemented by TASK_311.

The commander command keeps target and landing truth separate:

- `requested_lz_position` / `target_lz_position`
- `resolved_lz_position` / `actual_landing_position`
- `landing_deviation`
- `lz_accuracy_radius`
- `multiplayer_authority = server_resolved_lz`

Pilot and team skill reduce the V1 deviation radius. The requested LZ remains visible as the command target; the resolved LZ becomes visible once calculated.

## Freie Kampagnenlandung, 10.11.2026

FieldLandingContract prueft eine ebene freie Nachbarschaft samt Ausstieg,
Kartenrand und konkurrierendem Schiff fuer Soll und Ist. Die bestehenden
Skillradien sind Weltkoordinaten, keine Hexanzahlen. Unzulaessige Abweichung
faellt auf das vorher gepruefte Wunschfeld zurueck, nicht auf einen fernen Ort.
Rueckkehranker wird aus dem tatsaechlich geparkten craft_id gelesen.
Vier vorhandene Anflugrichtungen sind an einem kompakten Richtungskreis
waehlbar. Normaler Anflug bremst, faengt auf Hoverhoehe ab und setzt vor dem
Absetzen der Crew kontrolliert auf. Triebwerksdarstellung bleibt read-only.
