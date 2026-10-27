"""Compare full before/after test runs without mistaking old failures for cleanup regressions."""
import json
import re
from pathlib import Path

root = Path(__file__).resolve().parents[1]
raw = (root / 'build/cleanup_after_tests.log').read_bytes()
log = raw.decode('utf-16' if raw.startswith(b'\xff\xfe') else 'utf-8-sig')
assert 'Some tests failed.' in log or 'All tests passed!' in log, 'Test suite has not finished'
before = json.loads((root / 'tools/runtime_cleanup_baseline_tests.json').read_text())
after = [{'file': m[1], 'test': m[2]}
    for m in re.finditer(r'test/(.+?\.dart): (.+) \[E\]', log)]
def key(item):
    return (item['file'].split('/')[-1], item['test'])

baseline = {key(item) for item in before['failures']}
encountered = [item for item in after if key(item) not in baseline]
resolved = []
recheck = root / 'build/cleanup_font_recheck.jsonl'
if encountered and recheck.exists():
    raw_recheck = recheck.read_bytes()
    decoded = raw_recheck.decode('utf-16' if raw_recheck.startswith(b'\xff\xfe') else 'utf-8-sig')
    events = [json.loads(line) for line in decoded.splitlines() if line.startswith('{')]
    assert any(event.get('type') == 'done' and event.get('success') for event in events)
    started = {event['test']['id']: event['test'] for event in events if event['type'] == 'testStart'}
    successes = {(started[event['testID']]['url'].split('/')[-1], started[event['testID']]['name'])
        for event in events if event['type'] == 'testDone' and event['result'] == 'success'
        and not event.get('hidden') and event['testID'] in started}
    resolved = [dict(item, recheckLog='build/cleanup_font_recheck.jsonl',
        resolution='Original Medium/SemiBold font bytes restored; original offline font test passes with refreshed assets.')
        for item in encountered if key(item) in successes]
new = [item for item in encountered if key(item) not in {key(item) for item in resolved}]
summary = re.findall(r'\+(\d+)(?: -(\d+))?: (?:Some tests failed\.|All tests passed!)', log)[-1]
report = dict(beforePassed=before['passed'], beforeFailed=before['failed'],
    afterPassed=int(summary[0]), afterFailed=int(summary[1] or 0),
    preexistingFailuresStillPresent=[item for item in after if key(item) in baseline],
    encounteredFailuresResolvedBeforeDelivery=resolved, newFailures=new,
    noNewCleanupFailures=not new)
(root / 'tools/runtime_cleanup_test_comparison.json').write_text(json.dumps(report, indent=2)+'\n')
print(json.dumps({key: value for key, value in report.items()
    if key != 'preexistingFailuresStillPresent'}, indent=2))
assert not new, 'Investigate new failures before delivering the APK'
