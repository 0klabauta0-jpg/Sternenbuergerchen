"""Combine actual strict run records, retaining the failed evidence-write run.

Production stayed frozen. Only the movement verifier's evidence writer gained
an optional private output path, explicit close and a bounded open-error exit.
Simulation assertions did not change. No original report or log is overwritten.
"""
import hashlib
import json
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]
BASE=ROOT/"output/grafik_20261101"
original=BASE/"pass07_paths_check_runs/20261101T202904Z-pid123276/metadata/report.json"
retry=BASE/"pass07_paths_check_runs/20261101T203533Z-pid118556/metadata/report.json"
read=lambda p:json.loads(p.read_text(encoding="utf-8-sig"))
old,new=read(original),read(retry)
assert old["summary"]=={"selected":27,"passed":26,"failed":1}
assert new["summary"]=={"selected":1,"passed":1,"failed":0}
assert new["checks"][0]["name"]=="hex_movement" and new["checks"][0]["passed"]
assert all(row["passed"] or row["name"]=="hex_movement" for row in old["checks"])
for report,key in [(read(BASE/"pass07_paths_after_capture.json"),"runtime_sources_sha256"),(read(BASE/"pass07_runtime/native_check.json"),"source_sha256")]:
    for path,digest in report[key].items():
        assert hashlib.sha256((ROOT/path.removeprefix("res://")).read_bytes()).hexdigest()==digest,path
result=dict(old)
result["checks"]=[new["checks"][0] if row["name"]=="hex_movement" else row for row in old["checks"]]
result["summary"]={"selected":27,"passed":27,"failed":0}
result["evidence_kind"]="explicit_combination_of_actual_strict_invocations"
result["source_reports"]=[{"path":p.relative_to(ROOT).as_posix(),"sha256":hashlib.sha256(p.read_bytes()).hexdigest()} for p in (original,retry)]
result["scope_note"]="26 unchanged-production gates plus one actual25/25 movement retry after evidence-write isolation. Original file-open failure and timeout preserved. Old TASK158/159 remain failing with exact HEAD-baseline equivalence and are outside these27 focused checks."
dest=BASE/"pass07_paths_check_runs/verified_combined/metadata/report.json"
dest.parent.mkdir(parents=True,exist_ok=True)
dest.write_bytes((json.dumps(result,ensure_ascii=False,indent=2)+"\n").encode("utf-8"))
print(dest.relative_to(ROOT).as_posix())
