const fs = require('fs');
const path = require('path');

function find(dir) {
  const entries = fs.readdirSync(dir, { withFileTypes: true });
  for (const e of entries) {
    const p = path.join(dir, e.name);
    if (e.isDirectory() && !e.name.startsWith('.') && e.name !== 'node_modules') {
      const r = find(p);
      if (r) return r;
    } else if (e.name === 'query_compiler_fast_bg.wasm') {
      return p;
    }
  }
  return null;
}

const f = find('.');
const dest = 'app/generated/prisma/internal/query_compiler_fast_bg.wasm';
if (f && f !== dest) {
  console.log('Found wasm at:', f);
  fs.cpSync(f, dest);
  console.log('Copied to', dest);
} else {
  console.log('Wasm already at', dest);
}