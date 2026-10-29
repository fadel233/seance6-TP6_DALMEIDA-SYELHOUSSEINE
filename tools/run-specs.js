// Lance les tests (*.spec.js, *.test.js) d'un dossier : node tools/run-specs.js <dossier>
import { readdirSync, statSync } from 'node:fs';
import { join } from 'node:path';
import { spawnSync } from 'node:child_process';

const dossier = process.argv[2];
if (!dossier) { console.error('Usage : node tools/run-specs.js <dossier>'); process.exit(1); }

const trouver = d => readdirSync(d).flatMap(f => {
  const p = join(d, f);
  if (statSync(p).isDirectory()) return f === 'node_modules' ? [] : trouver(p);
  return /\.(spec|test)\.js$/.test(f) ? [p] : [];
});

const specs = trouver(dossier);
if (specs.length === 0) { console.error(`Aucun test trouvé dans ${dossier}`); process.exit(1); }
const r = spawnSync(process.execPath, ['--test', '--test-reporter=spec', ...specs], { stdio: 'inherit' });
process.exit(r.status ?? 1);
