#!/bin/bash
input=$(cat)
node -e "
const {execFileSync} = require('child_process');
const data = JSON.parse(process.argv[1]);
const R = '\x1b[0m', DIM = '\x1b[90m', CYAN = '\x1b[36m', MAG = '\x1b[35m';
const W = '\x1b[97m', GRN = '\x1b[32m', YEL = '\x1b[33m', RED = '\x1b[31m', BOLD = '\x1b[1m', BLU = '\x1b[94m';
const sep = ' ' + DIM + '|' + R + ' ';
const parts = [];

const dir = data.workspace?.current_dir || data.cwd || '';
if (dir) parts.push('\uD83D\uDCC2 ' + CYAN + dir + R);

let branch = '';
if (dir) {
  try {
    branch = execFileSync('git', ['-C', dir, 'branch', '--show-current'], {encoding:'utf8', stdio:['ignore','pipe','ignore']}).trim();
  } catch {}
}
parts.push('\uD83C\uDF3F ' + (branch ? MAG + branch : DIM + 'no branch') + R);

const model = data.model?.display_name || data.model?.name || '';
if (model) parts.push('\uD83E\uDD16 ' + BOLD + W + model + R);

if (data.version) parts.push('\u2728 ' + DIM + 'v' + data.version + R);

const rem = data.context_window?.remaining_percentage;
if (rem != null) {
  const r = Math.round(rem);
  const color = r > 50 ? GRN : r > 20 ? YEL : RED;
  const filled = Math.max(0, Math.floor(r / 10));
  const bar = '\u2588'.repeat(filled) + '\u2591'.repeat(10 - filled);
  parts.push('\u26A1 ' + color + bar + ' ' + r + '%' + R);
}

const dur = data.cost?.total_duration_ms;
if (dur != null) {
  const totalMin = Math.floor(dur / 60000);
  const h = Math.floor(totalMin / 60);
  const m = totalMin % 60;
  const t = h > 0 ? h + 'h ' + m + 'm' : m + 'm';
  parts.push('\u23F1 ' + BLU + t + R);
}

process.stdout.write(parts.join(sep));
" "$input" 2>/dev/null
