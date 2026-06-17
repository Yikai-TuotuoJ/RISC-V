from pathlib import Path
import csv
import re

ROOT = Path(__file__).resolve().parents[1]
LOG_DIR = ROOT / 'reports' / 'perf' / 'memory_latency_logs'
OUT_DIR = ROOT / 'reports' / 'perf'
MD_OUT = OUT_DIR / 'memory_latency_summary.md'
CSV_OUT = OUT_DIR / 'memory_latency_summary.csv'

fields = [
    'benchmark', 'mem_latency', 'cache_mode', 'pass', 'cycles', 'retired', 'cpi',
    'stalls', 'memory_stalls', 'load_use_stalls', 'load_stalls', 'store_stalls',
    'flushes', 'loads', 'stores', 'core_cycles', 'core_retired'
]

rows = []
for log in sorted(LOG_DIR.glob('*.log')):
    text = log.read_text(encoding='ascii', errors='ignore').replace('\x00', '')
    for line in text.splitlines():
        line = line.strip()
        if not line.startswith('MEMPERF:'):
            continue
        row = {'log': log.name}
        for key, value in re.findall(r'(\w+)=([^\s]+)', line):
            row[key] = value
        rows.append(row)

OUT_DIR.mkdir(parents=True, exist_ok=True)
with CSV_OUT.open('w', newline='', encoding='ascii') as f:
    writer = csv.DictWriter(f, fieldnames=['log'] + fields, extrasaction='ignore')
    writer.writeheader()
    for row in rows:
        writer.writerow(row)

with MD_OUT.open('w', encoding='ascii') as f:
    f.write('# Memory Latency Summary\n\n')
    if not rows:
        f.write('No MEMPERF lines were found.\n')
    else:
        f.write('| benchmark | mem_latency | cache_mode | pass | cycles | retired | CPI | stalls | memory_stalls | load_use_stalls | load_stalls | store_stalls | loads | stores | flushes |\n')
        f.write('|---|---:|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|\n')
        for row in rows:
            f.write('| {benchmark} | {mem_latency} | {cache_mode} | {pass} | {cycles} | {retired} | {cpi} | {stalls} | {memory_stalls} | {load_use_stalls} | {load_stalls} | {store_stalls} | {loads} | {stores} | {flushes} |\n'.format(**{k: row.get(k, '') for k in fields}))
        f.write('\n')
        f.write('Notes:\n')
        f.write('- `mem_latency=1` is the baseline one-cycle memory behavior.\n')
        f.write('- Higher latency values model extra MEM-stage wait cycles for loads and stores.\n')
        f.write('- `cache_mode=none`; Phase 10 implements latency infrastructure, not a cache hierarchy.\n')
        f.write('- CPI is a simulation-level microbenchmark estimate, not silicon signoff performance.\n')

print(f'Parsed {len(rows)} MEMPERF rows')
print(f'Wrote {MD_OUT}')
print(f'Wrote {CSV_OUT}')
