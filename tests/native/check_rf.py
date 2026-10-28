"""Check source-matched RF decoding cases and full-history version previews."""
from pathlib import Path
import hashlib
import json
import re

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
RUNS = HERE / 'results/rf-development'


def main():
    source = (ROOT / 'WIDGETS/SignalView/main.lua').read_bytes()
    checks = {}
    for name in ['verified-cases', 'compact-approved', 'final-v3']:
        log = (HERE / 'results' / ('rf-' + name + '.log')).read_text(encoding='utf-8')
        checks[name + '_complete'] = 'PHASE|complete' in log
        checks[name + '_no_errors'] = not re.search(
            r'CPU limit|Error in widget|Script error|Script syntax error|PANIC', log)
        checks[name + '_current_source'] = (RUNS / name / 'sd/WIDGETS/SignalView/main.lua').read_bytes() == source
        if name in ['verified-cases', 'compact-approved']:
            rows = re.findall(r'^RFMODE\|(\d+)\|true$', log, re.M)
            checks[name + '_51_unique_RF_cases'] = sorted(map(int, rows)) == list(range(1, 52))
        major = '3' if name == 'final-v3' else '4'
        checks[name + '_discovered_version'] = 'VERSION=' + major + '.0.0' in log
        checks[name + '_full_history'] = (RUNS / name / 'rf-full-history.png').exists()
        checks[name + '_stale_capture'] = (RUNS / name / 'rf-stale.png').exists()
    report = {'status': 'PASS' if all(checks.values()) else 'FAIL',
              'widget_sha256': hashlib.sha256(source).hexdigest(), 'checks': checks,
              'limits': 'Native EdgeTX 2.12.5 with synthetic telemetry/device info; no physical ELRS 3.x/4.x hardware validation.'}
    (RUNS / 'verification.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(report, indent=2))
    if report['status'] != 'PASS':
        raise SystemExit(1)


if __name__ == '__main__':
    main()
