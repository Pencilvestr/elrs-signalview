"""Verify source-matched history-selection scenarios and saved native settings."""
from pathlib import Path
import hashlib,json,re

ROOT=Path(__file__).resolve().parents[2]
RESULTS=ROOT/'tests/native/results'

def main():
    source=(ROOT/'WIDGETS/SignalView/main.lua').read_bytes()
    digest=hashlib.sha256(source).hexdigest()
    cases=(RESULTS/'history-cases.log').read_text()
    rows=re.findall(r'^HISTORY\|([^|]+)\|(true|false)$',cases,re.M)
    checks={
        '35_unique_cases':len(rows)==len({name for name,_ in rows})==35,
        'cases_passed':all(result=='true' for _,result in rows),
        'completed':'PHASE|complete' in cases,
        'cases_source_matches':(RESULTS/'history-cases/sd/WIDGETS/SignalView/main.lua').read_bytes()==source,
        'selection_persisted':'HISTORYCONFIG|2' in (RESULTS/'history-reopened.log').read_text(),
        'settings_source_matches':(RESULTS/'history-settings/sd/WIDGETS/SignalView/main.lua').read_bytes()==source,
    }
    for name in ['history-cases','history-settings','history-selected','history-reopened']:
        log=(RESULTS/(name+'.log')).read_text()
        checks[name+'_no_errors']=not re.search(r'Error in widget|CPU limit|Script syntax error|PANIC',log)
    regression=json.loads((RESULTS/'test-results.json').read_text())
    checks['five_native_targets']=len(regression['radios'])==5 and all(r['status']=='PASS' and r['widget_sha256']==digest for r in regression['radios'])
    for radio in ['tx16smk3','pa01']:
        for mode in ['receiver-signal','link-quality']:
            folder=RESULTS/'history-live'/radio/mode
            log=(folder/'run.log').read_text()
            checks[radio+'_'+mode]=('PHASE|theme-export-complete' in log
                and not re.search(r'Error in widget|CPU limit|Script syntax error|PANIC',log)
                and (folder/'theme-active-history.png').exists()
                and (folder/'sd/WIDGETS/SignalView/main.lua').read_bytes()==source)
    report={'status':'PASS' if all(checks.values()) else 'FAIL','widget_sha256':digest,'checks':checks,
            'limits':'Synthetic telemetry in native EdgeTX 2.12.5; physical-radio testing remains pending.'}
    (RESULTS/'history-verification.json').write_text(json.dumps(report,indent=2)+'\n')
    print(json.dumps(report,indent=2))
    if not all(checks.values()):raise SystemExit(1)

if __name__=='__main__':main()
