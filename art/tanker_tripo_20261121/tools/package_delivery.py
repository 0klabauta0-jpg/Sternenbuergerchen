"""Write local delivery metadata without touching the user's source scene."""
from pathlib import Path
import hashlib,json,shutil

ROOT=Path(__file__).resolve().parents[1]
WORKTREE=ROOT.parents[1]
def digest(path):return hashlib.sha256(path.read_bytes()).hexdigest()
original=Path('C:/dev/SternenBuergerchen/Assets/Trip/tanker.blend')
assert digest(original)==digest(ROOT/'source/tanker_tripo_original.blend')
files=['editable/tanker_102m_clean_segmented.blend','editable/tanker_102m_atlas_segmented.blend',
       'exports/tanker_102m.glb','exports/tanker_game.glb','exports/tanker_basecolor_atlas.png',
       'exports/tanker_102m_clean_segmented.glb']
manifest={'status':'separate_model_candidate','source':str(original),'source_sha256':digest(original),
          'source_unmodified':True,'runtime_integration':False,'files':[]}
for relative in files:
    path=ROOT/relative
    manifest['files'].append({'file':relative,'bytes':path.stat().st_size,'sha256':digest(path)})
download=Path('C:/Users/bjoer/Downloads/Tanker_102m_geprueft_20261121.blend')
shutil.copy2(ROOT/files[0],download)
assert digest(download)==digest(ROOT/files[0])
manifest['download_copy']=str(download)
(ROOT/'deliverable_manifest.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8')

status=WORKTREE/'docs/IMPLEMENTATION_STATUS.md'
old=status.read_bytes()
marker=b'## 2026-11-21 - Tripo-Tanker und Satellitenreferenz'
addition=b'''## 2026-11-21 - Tripo-Tanker und Satellitenreferenz
- Separater Modellkandidat in art/tanker_tripo_20261121/: Nutzerquelle erhalten,
  gleichfoermig auf 102 x 68.655 x 28.882 m skaliert; 82 editierbare Teile,
  15097 Tris. Kleine Topologiefehler bereinigt, 82 Texturen in einem Atlas.
- Godot-4.6.2-Import und native Vergleichsbilder im isolierten QA-Projekt gruen;
  Spiel-GLB 9.5744 Einheiten lang, passend zum Cutlass-Massstabsanker.
  Keine produktive Integration oder Nottankdienst-/Kauf-/Betankungslogik.
- KI-Vierseitenreferenz des Satelliten aus Mission 1 in art/satellite_turnaround_20261121/,
  transparentes PNG samt Vorlagen/Prompts; kein Austausch des Missionsmodells.
- Tasks: TANKER_TRIPO_MODELLPRUEFUNG_2026_11_21.md und SATELLITE_TURNAROUND_2026_11_21.md.
  Basis be0b30af9, Branch task/tanker-tripo-20261121; vorhandene WIP-Worktrees erhalten.

'''
if marker not in old:
    first_newline=old.index(b'\n')+1
    status.write_bytes(old[:first_newline]+b'\n'+addition+old[first_newline:])
print(json.dumps({'download':str(download),'source_unchanged':True,'manifest_files':len(files)}))
