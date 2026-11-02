"""Compare unmodified legacy assertion failures against an executed HEAD archive."""
from pathlib import Path
import hashlib,json,re
ROOT=Path(__file__).resolve().parents[5]
OUT=ROOT/'output/grafik_20261101/pass07_runtime'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def failures(p):
    text=p.read_text(encoding='utf-8-sig')
    labels=[line.split('ERROR:',1)[1].strip() for line in text.splitlines() if 'ERROR:' in line and 'FAIL' in line]
    counts=re.search(r'=== RESULTS: (\d+) passed, (\d+) failed ===',text)
    assert counts, str(p)
    assert len(labels)==int(counts[2]),str(p)
    assert not re.search(r'SCRIPT ERROR|Parse Error|leaked at exit',text),str(p)
    return {'passed':int(counts[1]),'failed':int(counts[2]),'labels':labels,'log_sha256':sha(p),'log':str(p.relative_to(ROOT)).replace('\\','/')}
def main():
    records=[]
    current_logs=OUT/'strict_runs/20261101T201928Z-pid135184/logs'
    for task,name in [(158,'editor_live_158'),(159,'legacy_view_159')]:
        baseline=failures(OUT/f'baseline_{task}.log')
        current=failures(current_logs/f'engine-check-{name}.log')
        assert baseline['passed']==current['passed'] and baseline['failed']==current['failed']
        assert baseline['labels']==current['labels'],f'TASK{task}: assertion failures differ'
        records.append({'task':task,'baseline':baseline,'candidate':current,'new_failure_labels':[],'all_original_tests_pass':False})
    result={'base_commit':'501201b0c56ebf3dee7b96541381f1c6de74ee64','assertion_sets_identical':True,'production_tests_modified':False,'overall_legacy_gates_pass':False,'scope':'Exact executed failure-label comparison only; existing failing assertions can mask untested differences. Neither test is relabeled green. Baseline application name changed solely for isolated fresh user data.','tests':records}
    (OUT/'legacy_baseline_comparison.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
    print('FRONTIER_LEGACY_BASELINE_MATCH '+json.dumps({'tasks':[158,159],'new_failure_labels':0,'legacy_gates_pass':False}))
if __name__=='__main__':main()
