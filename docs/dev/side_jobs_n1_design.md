# Nebenaufträge N1 – Entwurf (28.11.2026)

Björn: wiederholbar, Angebote verschwinden nach Heimlandungen, Ruf je Fraktion, Belohnungen auch Gegenstände und Rekruten,
Handel an Farm/Labor/Templer/Relaisgrat bleibt bei offenem Nebenauftrag möglich. Speicherformat-Erweiterung von Björn freigegeben (28.11.).

## Grundidee
Nebenaufträge laufen durch **dieselbe Auftrags-Pipeline** wie Kampagnenaufträge (annehmen → Abflug binden → aktivieren →
Einsatz → complete_job mit Laufzeitbeleg → apply_reward). Dafür lädt `singleplayer_campaign_state.gd` zusätzlich
`res://data/singleplayer/side_jobs.json` in `_jobs`, jeder Eintrag mit `"side": true`. `jobs.json` bleibt unverändert.

## Datei `data/singleplayer/side_jobs.json`
```json
{
  "factions": {"verwaltung": "Verwaltung", "mueller": "Müllers Hof", "templer": "Templer", "labor": "Shady Lab"},
  "jobs": {
    "<id>": {
      "id": "<id>", "title": "...", "description": "...", "location_id": "...", "scenario_id": "...",
      "required_step_ids": ["..."],
      "faction": "verwaltung",                      // Auftraggeber, Pflicht, muss in factions stehen
      "prerequisite_job_ids": ["outpost_recovery"],  // optional, alle müssen "completed" sein (Kampagne oder Neben)
      "min_reputation": {"templer": 0},              // optional, Annahme erst ab diesem Ruf
      "repeatable": true,                            // optional, Vorgabe true
      "cooldown_landings": 2,                        // nach Abschluss so viele Heimlandungen Pause (0..20)
      "offer_landings": 3,                           // Angebot steht so viele Heimlandungen, dann weg (0 = immer)
      "reappear_landings": 2,                        // weg für so viele Heimlandungen, dann wieder da
      "reward": {
        "credits": 100,
        "blueprint_id": "",                           // wie jobs.json
        "items": [{"item_id": "armor_light", "quantity": 1}],
        "recruits": 1,                                // Anzahl neuer Personen (Polisa-Profilweg)
        "reputation": {"verwaltung": 5, "templer": -3}
      }
    }
  }
}
```
Normalisierung in `singleplayer_job_contract.gd` als eigene Funktion `normalize_side_job(raw, locations, factions)`;
`normalize_job` bleibt für `jobs.json` unverändert. Bereiche: Credits 0..1 000 000, items ≤ 4 Einträge, quantity 1..10,
recruits 0..2, Ruf je Eintrag −50..50, Landungszahlen 0..20.

## Zustand (singleplayer_campaign_state.gd)
- Neue Felder: `_home_landings: int`, `_reputation: Dictionary` (Fraktion → int, Vorgabe 0, Grenzen −100..100).
- Je Nebenauftrag zusätzlich im Job-Eintrag: `completions: int`, `window_start: int` (Landung, ab der das Angebot steht),
  `cooldown_until: int` (Landung, ab der er nach Abschluss wieder angeboten wird).
- Neue Zustände nur für Nebenaufträge: `"cooldown"` (nach Abschluss, wiederholbar) und `"expired"` (Angebot abgelaufen).
  Nicht-wiederholbare bleiben `"completed"`.
- Neue Operation `"home_landing"` (über `apply_command`, eigene request_id je Landung, z. B. `home_landing:<Zähler>`):
  `_home_landings += 1`, dann für jeden Nebenauftrag:
  - `cooldown` und `_home_landings >= cooldown_until` → `offered`, `window_start = _home_landings`
  - `offered`, `offer_landings > 0` und `_home_landings >= window_start + offer_landings` → `expired`, `cooldown_until = _home_landings + reappear_landings`
  - `expired` und `_home_landings >= cooldown_until` → `offered`, `window_start = _home_landings`
  - angenommene/aktive/fehlgeschlagene laufen NICHT ab.
- `_acceptance_gate`: Nebenaufträge prüfen `prerequisite_job_ids` (alle completed **oder** bei Nebenaufträgen `cooldown`/`expired` mit completions ≥ 1)
  und `min_reputation` (Grund `reputation_required`, Text „Braucht Ruf <n> bei <Fraktion>."). Nicht annehmbar in `cooldown`/`expired`.
- `get_job_availability`: Nebenaufträge in `cooldown`/`expired` → `visible=false`. Neues Feld `side=true` und `landings_left`
  (Heimlandungen, bis das Angebot verschwindet; −1 = unbegrenzt) bzw. `cooldown_left`.
- `_finalize` für Nebenaufträge: `completions += 1`, completion_id = `"<id>:completed:<completions>"` (damit die
  Belohnung bei jeder Wiederholung neu gebucht wird – `apply_reward` ist je completion_id idempotent), Ruf aus
  `reward.reputation` buchen (geklemmt), dann Zustand `cooldown` (`cooldown_until = _home_landings + cooldown_landings`)
  bzw. `completed`, falls nicht wiederholbar. Receipt enthält `side: true` und die volle `reward` inkl. items/recruits.
- `has_open_job_at`, `free_visit_scenario_id`, `open_garrison_scenario_id`: Nebenaufträge **überspringen** → Handel und
  freier Besuch bleiben, solange der Nebenauftrag nicht als Ziel gewählt ist. Wird er gewählt, läuft sein Szenario; es nutzt
  dieselbe Karte wie der Besuch, damit der Handelsmarker aus `small_outposts.json` / `open_outposts.json` da ist.
- `validate_location_visit`: ein sichtbarer Nebenauftrag allein schaltet KEINEN Ort frei (Nebenaufträge haben als Vorgänger
  immer einen Kampagnenauftrag, der den Ort schon öffnet).
- Snapshot/Export: neue Schlüssel `home_landings`, `reputation`, `factions` (Anzeigenamen) im Snapshot.
- Restore (tolerant!): fehlende `home_landings`/`reputation` → 0/{}; fehlende Nebenauftrags-IDs im alten Stand → neu (`offered`,
  `window_start = 0`); unbekannte gespeicherte Nebenauftrags-IDs → still verwerfen (Kampagnenaufträge bleiben streng).
  Je Nebenauftrag aus dem Stand übernehmen: status, craft_id, retreat_count, reopen_at_home, completions, window_start, cooldown_until.
- `campaign_checkpoint_store.gd:286` (reward_receipts.size == completion_receipts.size) bleibt gültig, weil jede Ausführung je
  einen Eintrag in beiden erzeugt.

## Belohnungen (singleplayer_runtime_adapter.gd)
Nach dem erfolgreichen `apply_reward` (Einsatzende ~1510 und Hochladen ~2809) für Receipts mit `side: true`:
- `items`: in `base:homebase` buchen (Muster `grant_ammo_start_if_missing` / `_campaign_cargo`), Beleg-Kennung
  `side_items:<completion_id>` (idempotent). Ist das Lager voll: in den Frachtraum des Schiffes, sonst Meldung
  „Lager voll – <Gegenstand> liegt bereit" und als ausstehend merken (`pending_side_items` im Versorgungsstand, beim nächsten
  Öffnen der Basis erneut versuchen). Kein Gegenstand darf verloren gehen.
- `recruits`: je Rekrut ein Profil wie beim Polisa-Anwerben (Adapter ~3154: Profil erzeugen, `register_campaign_recruit`,
  `configure_inventory`, `configure_roster`/`set_loadout`, `provision_new_person`), unit_id `side_<job>_<completions>_<i>`
  (idempotent über die unit_id). Rekrut landet in der Basis, nicht im Schiff.
- Meldung im Smart Mobile/Ereignis: „Nebenauftrag erledigt: +100 Cr, Leichte Rüstung, 1 neue Person, Ruf Templer +5".

## Heimlandung (meta_layer_flow.gd)
In `_finish_space_home_landing` direkt nach `_restock_market_after_landing()` (~9671): Adapter-Methode
`record_home_landing()` → campaign-Befehl `home_landing`. (Zählt je gelandetem Schiff; bewusst so, kostet bei mehreren
Schiffen nur schnelleres Ablaufen.)

## Smart Mobile (singleplayer_job_board_presenter.gd)
- Eigener Abschnitt „Nebenaufträge" zwischen Kampagnen- und Daueraufträgen; Kampagnenabschnitt zeigt nur `side != true`.
- Karte: Titel, Auftraggeber (Fraktionsname), Ort, Belohnungszeile (Credits · Gegenstände · „1 neue Person" · Ruf ±),
  Zustandszeile („Angebot noch 2 Heimlandungen", „Braucht Ruf 5 bei Templer", „Schon 2× erledigt").
- Kopfzeile des Abschnitts: Ruf je Fraktion („Ruf: Verwaltung 5 · Müller 0 · Templer −3 · Labor 10").
- Annehmen über denselben Weg wie Kampagnenaufträge (`accept_job`); Zielwahl/Abflug unverändert.

## Inhalt N1
Kampagnen-Vorgänger: was den Ort öffnet (Bearbeiter liest jobs.json/locations.json).
1. `side_relay_silence` „Funkstille" – relay_ridge, verwaltung, drei Antennen prüfen (3× interaction_use), 100 Cr, Ruf verwaltung +5.
2. `side_farm_night_watch` „Nachtwache bei Müller" – muellers_farm, mueller, zwei Stellen prüfen + Plünderer, 80 Cr + `armor_light`, Ruf mueller +5, templer +2.
3. `side_lab_cold_samples` „Proben ohne Fragen" – shady_lab, labor, Probenkiste holen, 120 Cr + `rocket_launcher` + 2 `ammo_rocket`, Ruf labor +5, templer −3.
4. `side_templer_volunteer` „Ein Freiwilliger" – templanon, templer, min_reputation templer ≥ 0, Kranken zum Schiff begleiten/abholen (interaction_use), 60 Cr + 1 Rekrut, Ruf templer +5, labor −2.
Szenarien je als Kopie der Besuchsszenarien (gleiche Karte, Handelsmarker bleibt) mit zusätzlichen Schritten.
5. Kurierfahrt im Dreieck: drei neue Fracht-Daueraufträge in `standing_orders.json` (NUR anhängen) Farm→Templer Heilkräuter,
   Labor→Farm Dünger, Templer→Labor Aufputschmittel, je 4 Kisten, 30–40 Cr.

## Später (nicht N1)
Anzeige am Posten, Belohnungswahl, mehrere Wellen/Halten-Fortschritt, Ereignisse bei Heimlandung, Eskorte-Figur.
