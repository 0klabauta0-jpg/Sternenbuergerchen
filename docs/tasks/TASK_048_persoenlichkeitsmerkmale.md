# TASK 048 – Einfache Persoenlichkeitsmerkmale

## Ziel
Units erhalten 2–3 einfache Traits, die ihr Verhalten oder ihre Performance minimal beeinflussen und die Teamzusammenstellung interessanter machen.

## Pflicht vor Beginn
- Lies `docs/PROJECT_BRIEF.md`
- Lies `docs/ARCHITECTURE.md`
- Lies `docs/CODEX_RULES.md`
- Lies `docs/IMPLEMENTATION_STATUS.md`
- Pruefe den Git-Status

## Abhaengigkeit
- TASK_046 (Unit-Skill-Werte) muss vorher implementiert sein.
- TASK_047 (Skill-Wirkung) sollte vorher implementiert sein.

## Ist-Zustand (nach TASK_047)
- Units haben individuelle Skills mit Gameplay-Wirkung.
- Es gibt keine Persoenlichkeitsmerkmale oder Trait-Modifikatoren.
- Teamzusammenstellung basiert nur auf der Homebase-Checkbox-Auswahl ohne Informationsgrundlage.

## Aufgabe

### 1. Trait-Datenmodell
- Neues kleines RefCounted-Modell `UnitTrait` unter `res://scripts/npc/unit_trait.gd`:
  - `trait_id: String` (z.B. `"aggressive"`, `"cautious"`, `"steady"`, `"reckless"`, `"calm"`)
  - `display_name: String` (z.B. `"Aggressiv"`, `"Vorsichtig"`)
  - `skill_modifiers: Dictionary` (z.B. `{ "accuracy": +0.1, "toughness": -0.05 }`)
  - Methode: `apply_to_skills(skills: UnitSkills) -> void` – addiert Modifikatoren auf Skills

### 2. V1-Traits definieren
- 5 einfache Traits:
  - `aggressive`: accuracy +0.1, toughness -0.1
  - `cautious`: accuracy -0.05, toughness +0.1, speed -0.1
  - `steady`: accuracy +0.05, speed +0.05
  - `reckless`: speed +0.15, toughness -0.15
  - `calm`: leadership +0.15, accuracy +0.05

### 3. TestUnit: Traits integrieren
- `TestUnit` erhaelt ein Array `traits: Array[RefCounted]` (max 2 Traits pro Unit).
- Bei `_ready()` werden Trait-Modifikatoren auf die Skills angewendet.
- Export-Property `trait_ids: PackedStringArray` fuer Szenen-Konfiguration.

### 4. Trait-Factory
- Einfache statische Methode oder Konstanten-Dictionary das `trait_id` -> fertige `UnitTrait`-Instanz liefert.

### 5. Sichtbarkeit
- `TestUnit` zeigt Traits im Debug-Label: z.B. `[AGG, CALM]`.

### 6. MissionTestSetup: Trait-Zuweisung
- Friendly-Units erhalten jeweils 1–2 unterschiedliche Traits.
- Enemy-Units: keine Traits (oder einheitlich `steady`).

## Nicht-Ziele
- keine Team-Synergie-Effekte zwischen Units
- keine negativen Beziehungen zwischen Traits
- keine Trait-Entwicklung zur Laufzeit
- kein Trait-Balancing
- keine soziale Dynamik

## Akzeptanzkriterien
- Jede Unit kann 0–2 Traits haben
- Traits modifizieren die Skill-Werte nachvollziehbar
- Traits sind im Debug-Label sichtbar
- Unterschiedliche Trait-Kombinationen fuehren zu spuerbaren Skill-Unterschieden
- Bestehende Kampflogik und Skill-Wirkung funktionieren weiterhin

## Git-Schritte nach lokaler Pruefung
- `git status`
- `git add` nur relevante Dateien
- `git commit -m "Add unit personality traits with skill modifiers (TASK_048)"`
- `git push`
- `docs/IMPLEMENTATION_STATUS.md` aktualisieren
