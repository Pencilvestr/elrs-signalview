"""Summarize isolated native before/after runs; reject incomplete or mixed builds."""
from pathlib import Path
import hashlib
import json
import re

ROOT = Path(__file__).resolve().parents[1]
RUNS = ROOT / 'tests/native/results/performance'


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def profile(name):
    text = (RUNS / (name + '.log')).read_text()
    assert 'PHASE|complete' in text, f'Incomplete run: {name}'
    assert not re.search(r'CPU limit|Error in widget|PANIC|Script error', text), name
    rows = re.findall(r'^PERF\|refresh\|steady\|(\d+)\|([\d.]+)\|([\d.]+)$', text, re.M)
    live = re.findall(r'^PERF\|refresh\|steady\|(\d+)\|([\d.]+)\|([\d.]+)$',
                      text.split('PHASE|warning')[0], re.M)
    heap = re.findall(r'^PERFMEM\|([\d.]+)\|([\d.]+)\|([\d.]+)$', text, re.M)
    assert rows and live and len(heap) == 1, name
    count, total, maximum = map(float, rows[-1])
    live_count, live_total, _ = map(float, live[-1])
    start, retained, growth = map(float, heap[0])
    return {'run': name, 'source_sha256': digest(RUNS / name / 'sd/WIDGETS/SignalView/main.lua'),
            'steady_callbacks': int(count), 'mean_instruction_budget_percent': total / count,
            'live_instruction_budget_percent': live_total / live_count,
            'max_instruction_budget_percent': maximum,
            'start_heap_KiB': start, 'retained_heap_KiB': retained, 'heap_growth_KiB': growth}


def main():
    baseline = [profile('baseline-control')]
    candidate = [profile('final-control')]
    current = digest(ROOT / 'WIDGETS/SignalView/main.lua')
    reference = digest(RUNS / 'beta3-baseline.lua')
    assert all(row['source_sha256'] == current for row in candidate)
    assert all(row['source_sha256'] == reference for row in baseline)
    for name in ['main.lua', 'profile.lua', 'profile-enabled.lua', 'reference-enabled.lua']:
        assert digest(RUNS / 'baseline-control/sd/WIDGETS/LabTest' / name) == digest(
            RUNS / 'final-control/sd/WIDGETS/LabTest' / name), 'Mismatched observer: ' + name
    log = (RUNS / 'equivalence-bounded.log').read_text()
    assert 'PHASE|complete' in log
    assert not re.search(r'CPU limit|Error in widget|Output differs|PANIC', log)
    cases = re.findall(r'^EQUIV\|(\d+)\|true$', log, re.M)
    assert list(map(int, cases)) == list(range(1, 131))
    assert digest(RUNS / 'equivalence-bounded/sd/WIDGETS/SignalView/main.lua') == current
    old = (RUNS / 'beta3-baseline.lua').read_text()
    needle = 'local v=panel==1 and point[antenna+1] or point[1]'
    assert old.count(needle) == 1
    corrected = old.replace(needle, 'local index=panel==1 and antenna+1 or 1\n        local v=point[index]')
    assert (RUNS / 'equivalence-bounded/sd/WIDGETS/LabTest/reference.lua').read_text() == corrected
    before, after = baseline[-1], candidate[-1]
    reductions = {key: 100 * (before[key] - after[key]) / before[key]
                  for key in ['live_instruction_budget_percent', 'retained_heap_KiB',
                              'max_instruction_budget_percent']}
    report = {'firmware': 'EdgeTX 2.12.5', 'target': 'TX16S MK3 simulator, 800x480',
              'baseline': baseline, 'candidate': candidate, 'relative_reduction_percent': reductions,
              'equivalence_cases': 130,
              'reference_correction': 'Only the released missing-antenna and/or fallback is corrected in the comparison oracle.',
              'limits': ['getUsage measures Lua instruction budget, not total CPU time.',
                         'Heap is isolated Windows x64 Lua VM memory after test-only full GC at 45 seconds.',
                         'Each run uses 60 seconds of changing live telemetry, then warning/stale/recovery/exit.',
                         'Radio CPU utilization, peak heap, UI latency and physical RAM savings are unmeasured.']}
    destination = ROOT / 'docs/performance-results.json'
    destination.write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps({'before': before, 'after': after, 'reduction_percent': reductions}, indent=2))


if __name__ == '__main__':
    main()
