#!/usr/bin/env python3
"""Archive reproductible de la source, sans caches, chemins locaux ou secrets."""
from pathlib import Path
from zipfile import ZipFile,ZIP_DEFLATED
root=Path(__file__).resolve().parents[1]
out=root/'livraison_la_bafouille';out.mkdir(exist_ok=True)
excluded={'.git','.codex','.agents','.aws','.idea','.dart_tool','.gradle','build','ephemeral','livraison_la_bafouille','node_modules'}
with ZipFile(out/'La_Bafouille_v1.0.1_source.zip','w',ZIP_DEFLATED) as z:
 for path in sorted(root.rglob('*')):
  relative=path.relative_to(root)
  if any(p in excluded for p in relative.parts) or path.is_symlink() or not path.is_file():continue
  if path.name in {'local.properties','key.properties','.flutter-plugins-dependencies','.DS_Store'} or path.suffix in {'.jks','.keystore','.iml','.log'}:continue
  z.write(path,Path('La_Bafouille')/relative)
print(out/'La_Bafouille_v1.0.1_source.zip')
