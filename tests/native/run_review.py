"""Run source-matched history-review checks in native EdgeTX simulators."""
from pathlib import Path
import argparse,concurrent.futures,hashlib,json,os,re,subprocess,sys
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[1]
RADIOS=['tx16smk3','tx16s','tx15','nv14','pa01']
def run_case(pair):
    radio,suite=pair
    folder=HERE/'results/review'/radio/suite
    folder.mkdir(parents=True,exist_ok=True)
    with (folder/'run.log').open('w',encoding='utf-8') as output:
        try:
            code=subprocess.run([sys.executable,str(HERE/'worker.py'),'--radio',radio,'--run-dir',str(folder),'--review-suite',suite],cwd=ROOT,stdout=output,stderr=subprocess.STDOUT,timeout=100).returncode
        except subprocess.TimeoutExpired: code=-1
    log=(folder/'run.log').read_text(encoding='utf-8',errors='replace')
    errors=re.findall(r'.*(?:CPU limit|Error in widget|Script syntax error|PANIC|attempt to|not enough memory|Archive test failed).*',log)
    copied=folder/'sd/WIDGETS/SignalView/main.lua'
    source=(ROOT/'WIDGETS/SignalView/main.lua').read_bytes()
    checks={'process':code==0,'source_match':copied.exists() and copied.read_bytes()==source,'no_errors':not errors,'complete':'PHASE|complete' in log}
    if suite=='timing':
        cases=dict(re.findall(r'SCROLLGAP\|([^|]+)\|(true|false)',log))
        checks['timing_cases']=len(cases)==10 and all(v=='true' for v in cases.values())
        checks['timing_complete']='SCROLLGAPDONE' in log
    else:
        cases=dict(re.findall(r'REVIEWCHECK\|([^|]+)\|(PASS)',log))
        checks['archive_complete']='REVIEWDONE|PASS' in log and 'REVIEWEDGES|PASS' in log
    result={'radio':radio,'suite':suite,'pass':all(checks.values()),'source_sha256':hashlib.sha256(source).hexdigest(),'checks':checks,'cases':cases,'errors':errors}
    (folder/'report.json').write_text(json.dumps(result,indent=2))
    print(radio,suite,result['pass'],flush=True)
    return result
if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--radios',nargs='+',choices=RADIOS,default=RADIOS);parser.add_argument('--suite',choices=['timing','archive','both'],default='both');args=parser.parse_args()
    suites=['timing','archive'] if args.suite=='both' else [args.suite]
    with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool: results=list(pool.map(run_case,[(r,s) for r in args.radios for s in suites]))
    (HERE/'results/review'/('summary-'+args.suite+'.json')).write_text(json.dumps(results,indent=2))
    if not all(r['pass'] for r in results):sys.exit(1)
