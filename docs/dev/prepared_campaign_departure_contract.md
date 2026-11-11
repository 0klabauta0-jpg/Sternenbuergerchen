# Prepared Campaign Departure (unverdrahtet)

Der bestehende Campaignowner kann einen zusammengehoerigen bind_departure- und optionalen activate_job-Patch vorbereiten, revalidieren und still publizieren. Es gibt noch keinen produktiven Aufrufer. Root muss kuenftig ALLE Owner vor jeder gemeinsamen Mutation pruefen und erst nach allen Publications Events senden.

configure_departure_preparation_authority bindet eine echte Objectidentitaet. trusted_context enthaelt diese authority, transaction_id und Array[String] built_home_pad_ids. Kein runtime_authorized/departure_authorized-Bool allein erlaubt die neue API. Das ist ein ausdruecklicher Inprocessvertrag, keine Isolation gegen beliebigen Code im selben Prozess.

prepare_departure benutzt nur eine private kleine Runtimekopie der tatsaechlich von vorhandener bind/activate-Logik gelesenen Inputs, nie export_state/restore_state oder einen Vollownerswap. Der resultierende Patch betrifft ein Craftbinding, hoechstens einen Jobstatus/Craftkey, die zwei Legacyrequestbelege und das Revisionsdelta. Betroffene Inputs inklusive Selection, Pads und Receiptkeys werden beim Commit erneut verglichen; Revision allein reicht wegen already_active-Noops nicht.

Eine leere job_id hat kein Activationcommand und keinen Phantomjobpatch. Identische Wiederholung wird nur anhand eines eigenen vollstaendigen Gruppenbelegs akzeptiert. Alte einzelne Subreceipts oder ein uneindeutiger Job/Craft-Teilstand werden abgewiesen statt halb weitercommittet. Gruppen-ID bindet Commands und Kontext vollstaendig; geaenderte Nutzung ist ein Konflikt. Der stille _publish_prepared_departure(candidate,validation)-Tail hat nach dem ersten Write keine weitere Validierung, Callbacks, Save-/Dateizugriffe oder Signale. Eigentum und Objektidentitaet bleiben beim selben Campaignowner.

Quelle: docs/tasks/PREPARED_CAMPAIGN_DEPARTURE_2026_11_11.md. Keine Aenderung von Fleet/Travel, Root, Supply, Adapter oder bestehenden produktiven Commands durch diesen Slice.

Der aktuelle Kandidat invalidiert seine transienten Belege/Authority bei erfolgreichem Lifecycleconfigure oder Restore. Die private Vorbereitung selbst benutzt diese Save-/Lifecyclepfade nicht. Vor dem ersten Patchwrite werden die zu veroeffentlichenden Dictionarys vom Caller abgetrennt, damit spaetere Kandidatenmutation keine Livebindung veraendert. Eigener kleiner Beleg: 12/0, weiterhin runtime_wired=false.
