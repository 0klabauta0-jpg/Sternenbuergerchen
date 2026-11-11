# Polisa: kameraunabhaengige gebundene Bodengeometrie

Neue lokale Stationskaeufe erhalten beim validierten Admit genau das zuvor
fuer Pad-/Belegungspruefung verwendete `ground_body_profile`. Es liegt neben
bereits vorhandener Position und Pad-ID in `_field_landing_by_craft[craft_id]`.
Profilfelder: `craft_id`, `model_id`, `asset_id`, `bounds:AABB`, positive endliche
`model_scale`, `cell_size` und endliches `yaw_degrees`. Die Rendererquelle fuer
neue Kandidaten bleibt `get_station_craft_body_projection`; Assetidentitaet wird
gegen den vorhandenen Frontier-Schiffkatalog geprueft, keine geratenen Groessen.

Belegte andere Schiffe werden mit bestehender Sequence-/Cardposition und ihrem
gebundenen Profil projiziert. Fehlendes, ungueltiges oder falsch zugeordnetes
Profil liefert `ground_ship_geometry_unbound`; Preview bindet/repariert nichts.
Keine Kameraneuberechnung geparkter Fremdschiffe. Alle Profile sind reine
detached Value-Dictionaries; primitive Typen/Endlichkeit, positive Bounds und
exakte Craft-/Modell-/Assetzuordnung werden vor Benutzung geprueft.
Der bestehende seltene `owner_signature`-Digest enthaelt neben Cards/Sequences
genau die validierten Profile der in dieser Admission belegten Schiffe; keine
fremden Runtime-/Inventarvollscans oder neue Revision. Admission revalidiert
ohnehin synchron. Der gegenwaertige Flowcommit vergleicht Ort/Identity/Pad,
aber keinen eigenen `owner_signature`-Schluessel.

Nur neue Stationskaeufe produzieren hier Bindungen. Normale ankommende Dropships
und spaetere Rebind-/Assetwechsel benoetigen ihren eigenen ausdruecklichen
Tabletop-Ownerpfad. Diese Aenderung behauptet keinen vollstaendigen Produzenten
fuer alle bestehenden Besucher und keine Grafik-/Save-/Performanceabnahme.
