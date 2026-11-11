# Polisa R05: natives Produktkartenmenue

Geaendert: bestehendes PolisaStationScreen mit kompakten umbrochenen Produktkarten statt langen Zeilen. Ruestungen zeigen die vollstaendige Vorderansicht der freigegebenen 2D-Zielblaetter (AtlasTexture, Originaldateien unveraendert), beschriftet als Illustration im Tooltip. Quellen/Hashes: Assets/curated/ui/polisa_armor/provenance.json. Kein geaendertes Ruestungsmodell.

Pruefung: Godot4.6.2 check-only fuer polisa_station_screen.gd Exit0. Nativer privater D3D12-Forward+-Capture `capture_shop.gd` benutzt das echte Produktpanel mit neu konfiguriertem SupplyState und echtem Angebotskatalog. Keine echte Kampagnenlandung in dieser Probe. `polisa_purchase_menu.png` und `polisa_menu_after_purchase.png` wurden geoeffnet: ganze Helme/Stiefel sichtbar, Kauf-/Ausrustbuttons passen in die Karten; Rucksack bleibt kompakt.

Echter Kaufbutton in der Probe: 500 auf445Cr, Bestand leichte Ruestung6 auf5, Schiffslager0 auf1 im ausgewaehlten privaten craft:polisa_preview. Supply.apply_command prueft Kapazitaet/Bestand/Preis; UI speichert keine Inventarwahrheit. Warenverkauf benutzt weiterhin den bestehenden Sellcommand aus genau diesem Schiffslager; Kaufen liefert direkt dorthin. Kein erfundener stationsinterner Zwischencontainer oder neue Transferwahrheit.

Finaler begrenzter Lauf native_shop_r05_fixed: Exit0, keine Scriptfehler, eine ObjectDB-Shutdownwarnung im Capture-Harness. Erster Lauf scheiterte am nicht existierenden execute_command im alten privaten Previewadapter; auf den vorhandenen Supply.apply_command und den expliziten privaten craft_id-Kontext korrigiert. Erstlaufprotokoll bleibt erhalten. Die Warnung ist keine Framerate-/Lebenszyklusabnahme.

Groessere Tests, Reise-/Inventar-/Save-End-to-End und native Stations-R05-Abnahme bleiben getrennt. Keine Mainintegration oder neue EXE.
