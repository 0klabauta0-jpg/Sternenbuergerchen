# TASK_1126 - Connected First Contact Local Marker and Label Hierarchy

## Ziel / Problem
Nach TASK_1125 liegt das komplette lokale Fireteam im freien Kamerarahmen. Im gemeinsamen Erstkontaktcluster konkurrieren jedoch grosse gelbe Selection-Ringe, Unit-Status-Badges wie `CONTACT` und der eigentliche Kontaktmarker um dieselbe Stelle.

## Sinnhaftigkeit / Ursache
Der bestehende Order-Payload kennzeichnet den verbundenen Kontakt bereits mit `world_label_focus_mode = connected_contact`. Die Selection- und Unit-Badge-Pfade behandeln diesen Fokus aber wie den Defaultzustand. Dadurch ist die visuelle Rangfolge umgekehrt: redundante Unit-Texte und Auswahlflaechen sind lauter als das taktisch relevante Ziel.

## Umfang
- Connected-Contact-Fokus erhaelt eine explizite read-only Markerhierarchie.
- Selection-Ringe bleiben sichtbar, werden aber kleiner und transparenter als der Contact-Marker.
- Routine-Badges (`CONTACT`, `ENGAGE`, `MOVE` usw.) werden in diesem Fokus unterdrueckt.
- Kritische Vital-/Health-Badges bleiben sichtbar.
- Render-Snapshot dokumentiert aktive Hierarchie und verwendete Markerwerte.
- BLUE-/GOLD-Produktcaptures werden neu bewertet.

## Nicht-Ziele
- Keine Positionsaenderung an Units oder Contacts.
- Kein Contact-, Combat-, FOW- oder Selection-State im Visualcode.
- Kein kompletter World-Label-Rewrite.
- Kein per-frame SceneTree-Scan.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_1125_connected_first_contact_local_team_contact_cluster_readability.md`
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/ARCHITECTURE.md`

## Akzeptanzkriterien
- Contact-Marker bleibt der staerkste lokale Bodenmarker.
- Selection bleibt erkennbar, verdeckt aber Unit und Contact nicht.
- Redundante Routine-Badges verschwinden im Connected-Contact-Fokus.
- `DOWN`, `BLEEDOUT`, `RESPAWN` und `HP` bleiben erhalten.
- BLUE und GOLD behalten korrekte lokale Perspektive, Camera-Size und HUD-freie Bounds.
- Multiplayer- und Performance-Gates bleiben gruen.

## Betroffene Dateien
- `scripts/terrain/terrain_map_3d_view.gd`
- `scripts/tests/task_1126_connected_first_contact_local_marker_label_hierarchy.gd`
- `scripts/tests/task_1119_connected_first_contact_three_peer_product_visual_playtest.gd`
- Status-, Roadmap- und HTML-Berichtsdokumentation

## Lokale Pruefung
- TASK_1126 RED/GREEN.
- TASK_1119 headless und Real Window BLUE/GOLD.
- TASK_1125, TASK_1124, TASK_1104 und TASK_222.
- `git diff --check`.

## Risiken / offene Punkte
Selection darf nicht unsichtbar werden. Die Hierarchie reduziert Radius und Alpha nur im bestehenden Connected-Contact-Fokus und laesst alle anderen Editor-, Offline- und Missionszustaende unveraendert.

## Ergebnis
- Connected-Contact-Selection verwendet Radius `0.20` und Alpha `0.24`; der eigentliche Contact-Marker bleibt mit Radius `0.26` staerker.
- Routine-Unit-Badges werden im Fokus unterdrueckt, Health-/Vital-Badges bleiben sichtbar.
- Redundante Tactical-Communication-`contact_report`-Marker und ihre `CONTACT`-Labels werden im Connected-Fokus nicht zusaetzlich neben dem bestehenden ContactRoot gerendert.
- Detached Mission-Konfiguration behandelt beide Multiplayer-Gates jetzt fehlerfrei als disconnected.
- BLUE und GOLD enthalten im echten Full-HD-Produktbild keine sichtbaren Routine-Labels mehr.

## Verifikation
- TASK_1126: 13/13.
- TASK_1119: 33/33 headless, 39/39 BLUE Real Window, 39/39 GOLD Real Window.
- TASK_1125: 10/10; TASK_1124: 11/11; TASK_839: 31/31; TASK_1104: 31/31; TASK_222: 82/82.
- TASK_274: Script-Error durch detached Multiplayer-Zugriff beseitigt; 74/76 Assertions gruen. Zwei bestehende HUD-Bubble-/Mini-Card-Ankerpruefungen bleiben als TASK1127 offen.
