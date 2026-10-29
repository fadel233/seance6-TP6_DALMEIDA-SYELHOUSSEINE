// Règle de dépendance : aucun fichier d'un dossier domain/ n'importe l'extérieur.
import { readdirSync, readFileSync, statSync } from 'node:fs';
import { join } from 'node:path';

const racine = process.argv[2] ?? '.';
const fichiersDomain = d => readdirSync(d).flatMap(f => {
  const p = join(d, f);
  if (statSync(p).isDirectory()) return f === 'node_modules' || f === '.git' ? [] : fichiersDomain(p);
  return p.split(/[\\/]/).includes('domain') && p.endsWith('.js') ? [p] : [];
});

const motif = /^\s*(import\s[^;]*from\s|import\s*['"(]|export\s[^;]*from\s)|require\s*\(/m;
const fautifs = fichiersDomain(racine).filter(f => {
  const source = readFileSync(f, 'utf8').split('\n').filter(l => !l.trim().startsWith('//')).join('\n');
  return motif.test(source);
});

if (fautifs.length) {
  console.error('✗ Règle de dépendance violée :');
  fautifs.forEach(f => console.error('  - ' + f));
  process.exit(1);
}
console.log("✓ Règle de dépendance respectée : aucun fichier domain/ n'importe l'extérieur.");
