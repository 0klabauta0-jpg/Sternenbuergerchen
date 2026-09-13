# N4 · Save-Lebenszyklus

13.09.2026: `tests/save_lifecycle_run.ps1` startet vier echte Produktprozesse unter Godot4.6.2. **12/12 Prüfungen bestanden**, alle vier Enginefehlerlogs leer.

Evidenz: `C:/Users/bjoer/AppData/Local/Temp/sternenbuergerchen-lifecycle-n4-e9d10bed60e44c90a607bf930b3a469a`.

1. Neue echte Sitzung nimmt den Auftrag an, pausiert und speichert beim normalen Schließen.
2. Der Runner entfernt ausschließlich spätere Schema-Erweiterungen aus diesem echten Save (neue Items/Rezepte, Sitzplan, Winkel und persönliche Rucksäcke). Der zweite normale Produktstart migriert v1 auf Schema4, behält Auftrag und Pause, erzeugt leere gültige Sitze/Rucksäcke und lässt echte neue Werkbankarbeit zu.
3. Ein ungültiger Save bleibt nach abgelehntem Start unangetastet. Explizites erfolgreiches Speichern aktiviert Autosave wieder. Ein gezielt unerreichbarer Test-Savepfad verhindert das Schließen und meldet den Fehler; anschließend wird korrekt gespeichert.
4. Der nächste normale Start bestätigt erhaltenen Fortschritt und gespeicherte fortgesetzte Werkbankarbeit.

Der echte initiale v4-Save liegt zusätzlich als `initial-schema4.json` vor, das historische Eingabeformat als `legacy-input-v1.json`. Keine Karrierewerte werden für Erfolg gesetzt. Alle Savepfade und APPDATA liegen im neuen isolierten Testordner. Produktdateien wurden für diese Anpassung nicht verändert.
