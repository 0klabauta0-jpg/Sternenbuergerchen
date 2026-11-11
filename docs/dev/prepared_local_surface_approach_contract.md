# Prepared Local Begin Approach

Aktueller Anschluss seit Elternintegration e205137d6: Root benutzt den folgenden
vorbereiteten Travelpatch fuer die produktive Abflug-/Anfluggruppe einschliesslich
Saum-/Footprintpruefung und stiller Flightdeaktivierung/Raumindexfreigabe. Nachweis:
`docs/qa/orbit_owner_integration_20261111/parent_departure`. Native Boarding- und
Gesamtreisepruefung bleiben offen. Die nachfolgende Beschreibung und 10/0-Zahl
beziehen sich auf den urspruenglichen unverdrahteten Owner-Slice.

Die vorhandenen drei Fleet-Prepared-APIs akzeptieren zusaetzlich operation begin_approach mit exakt zwei Payloadfeldern craft_id und location_id, beide Strings. Der bestehende registrierte Rootkontext hat weiterhin neun Felder und dieselbe Objectauthority-, Serial-, Seal- und Replaygrenze. Kein neuer Commandrouter oder Productcaller.

Erlaubt ist nur bestehende Travelphase orbit bei echtem local+tactical Flight. SourceArea==TargetArea==Flightarea==kanonische Bodylayout-ID. Zielort liegt laut location_orbits am echten Travelorbit und genau dessen Body muss surface_location_id==Zielort ausweisen. Stationen und homebase sind kein neuer allgemeiner Oberflaechenanflug.

Vorbereitung und Validate binden Flightobjekt/Craft/Revision/Frame/Area/Mode. Der Patch setzt nur Travelphase approach, Zielort und Revision+1, ohne Flightpose. Er traegt kein Gate-/Access-Token: Root muss echten Saum, gesamten Footprint, Claims und Registry vor dem Gruppencommit pruefen. Nach gemeinsamer Revalidierung darf Root Flight deaktivieren/deindizieren und den privaten Traveltail still publizieren. Dieser liest Flight nicht erneut; public Commit nach Flightaenderung bleibt stale. Vorhandenes trusted finish_approach bei inactive bleibt ein reiner Phasenschritt.

advance fuer strategischen Warpabschluss und enter_orbit fuer bisherigen strategischen beziehungsweise inaktiven lokalen Rueckweg bleiben erhalten. Kein vorbereiteter Warpabflug, Fuel-/Campaigncommit, Surface-/Missionload oder produktiver Gesamtanflug wird dadurch behauptet. Quelle: docs/tasks/PREPARED_LOCAL_BEGIN_APPROACH_2026_11_11.md.

Aktueller kleiner Beleg: 10/0 Ownerchecks und beide Compiles0, weiterhin runtime_wired=false. Auch ein vorhandenes Ziel am selben Orbit ohne expliziten surface_location_id-Link (distress_orbit) reicht nicht. Echte Flightdeaktivierung erfolgt nach Validate, vor privatem Publicationtail; unveraenderte Pose ist nachgewiesen. Rootgeometrie, Registry und Claims sind weiterhin keine vom Travelcandidate erteilte Freigabe.
