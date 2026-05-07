# TASK_279 - LZ Security Air Asset Tactical Playability Smoke

## Ziel
Ein zusammenhaengender Missions-Smoke soll pruefen, ob LZ-Sicherung, Fireteam-Taktik, Enemy-Heavy-Threat, Dropship-/Frachter-Risiko, Explosion, Kommunikation und Meta-Folgen spielbar zusammenpassen.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_272 - Multi Fireteam Coordinated Area Plan
- TASK_274 - Tactical Communication Feedback Layer
- TASK_276 - Tactical Breakout and Exception Behavior
- TASK_277 - Dropship Freighter Anti Armor Threat Contract
- TASK_278 - Air Asset Loss Recovery Meta Loop

## Kontext
Die Systeme muessen gemeinsam funktionieren: Der Spieler befiehlt zwei Fireteams, die LZ zu nehmen/sichern. Ein Enemy-AT-Team bedroht das Dropship. Fireteams kommunizieren, reagieren und entweder wird die LZ gesichert oder das Air Asset wird getroffen, sichtbar und mit Folgen.

## Umfang
1. Testmission:
   - Kleine 32x32- oder 64x64-Karte.
   - LZ, Deckung, Enemy-AT-Team, zwei Friendly-Fireteams.
   - Optional sicherer und riskanter Pfad.
2. Erfolgsfall:
   - Fireteams sichern LZ.
   - Dropship landet oder bleibt sicher.
   - Kommunikation meldet Rollen/Status.
3. Bedrohungsfall:
   - Enemy-AT bekommt LOS/Range.
   - Warnung/Threat-Zustand.
   - Spieler kann reagieren.
4. Verlustfall:
   - Air Asset wird getroffen/zerstoert.
   - Explosion/VFX/SFX.
   - Mission-State und Debrief.
   - Homebase/FOB Meta-Status.
5. Verifier:
   - Authority.
   - Snapshot-Felder.
   - Kommunikationsereignisse.
   - Keine UI-only Wahrheit.
   - Kein Softlock.

## Nicht-Ziele
- Kein finaler Balancewert fuer AT-Waffen.
- Kein vollstaendiger Kampagnenmodus.
- Kein spektakulaerer Crash-Cinematic.

## Akzeptanzkriterien
- [x] Erfolgsfall LZ secure laeuft ohne Air-Asset-Schaden.
- [x] Bedrohungsfall zeigt klare Warnung und Ursache.
- [x] Verlustfall erzeugt Explosion, Status, Debrief und Meta-Folge.
- [x] Fireteam-Kommunikation erklaert Rollen, Ausbrueche und Ergebnis.
- [x] Multiplayer-/Snapshot-Grenzen bleiben sauber.
- [x] Ein Smoke prueft Mission und Meta-Roundtrip.

## Erwartete Dateien
- `scripts/tests/task_279_lz_security_air_asset_tactical_playability_smoke.gd`
- `docs/reports/lz_security_air_asset_playability_smoke.md`
- optional `maps/test_lz_air_asset_threat_fixture.json`
- `docs/tasks/TASK_279_lz_security_air_asset_tactical_playability_smoke.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_279_lz_security_air_asset_tactical_playability_smoke.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_160_tactical_playability_verifier.gd`
- [x] `git diff --check`

## Risiken
- Der Smoke ist lang und lokalisiert Fehler schlechter als Einzelverifier.
- Ohne gutes Feedback wirkt Air-Asset-Verlust unfair.

## Naechster Schritt
Nach TASK_279 kann TASK_280 Taktikprofile im Editor und in Missionsszenarien authorbar machen.
