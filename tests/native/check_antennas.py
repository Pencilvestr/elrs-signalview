"""Validate source-matched antenna scenarios, previews and native choice persistence."""
from pathlib import Path
import hashlib
import json
import re

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
RUNS = HERE / 'results/antenna-development'


def main():
    source = (ROOT / 'WIDGETS/SignalView/main.lua').read_bytes()
    checks = {}
    for name in ['cases', 'single1', 'single2']:
        log = (RUNS / (name + '.log')).read_text(encoding='utf-8')
        checks[name + '_completed'] = 'PHASE|complete' in log
        checks[name + '_no_errors'] = not re.search(
            r'CPU limit|Error in widget|Script error|Script syntax error|PANIC', log)
        checks[name + '_current_source'] = (RUNS / name / 'sd/WIDGETS/SignalView/main.lua').read_bytes() == source
    log = (RUNS / 'cases.log').read_text(encoding='utf-8')
    rows = re.findall(r'^ANTENNA\|([^|]+)\|(true|false)$', log, re.M)
    checks['58_unique_scenarios'] = len(rows) == len(set(name for name, _ in rows)) == 58
    checks['all_scenarios_passed'] = all(result == 'true' for _, result in rows)
    for name in ['single1', 'single2']:
        checks[name + '_full_history_capture'] = (RUNS / name / 'antenna-full-history.png').exists()
    selected = (RUNS / 'choices-selected.log').read_text(encoding='utf-8')
    reopened = (RUNS / 'choices-reopened.log').read_text(encoding='utf-8')
    checks['choice_started_single'] = 'ANTENNACONFIG|single' in selected
    checks['choice_reopened_dual'] = 'ANTENNACONFIG|dual' in reopened
    checks['choice_current_source'] = (RUNS / 'settings/sd/WIDGETS/SignalView/main.lua').read_bytes() == source
    checks['choice_no_errors'] = not re.search(r'CPU limit|Error in widget|Script error|PANIC', selected + reopened)
    report = {'status': 'PASS' if all(checks.values()) else 'FAIL',
              'widget_sha256': hashlib.sha256(source).hexdigest(), 'checks': checks,
              'limits': 'Synthetic telemetry in EdgeTX 2.12.5 native simulator; physical receiver count/health is not identified.'}
    (RUNS / 'verification.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(report, indent=2))
    if report['status'] != 'PASS':
        raise SystemExit(1)


if __name__ == '__main__':
    main()
