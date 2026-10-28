#!/usr/bin/env python3
"""Copie l'APK release courant dans la livraison, nommé d'après pubspec.yaml."""
from pathlib import Path
import re, shutil
root=Path(__file__).resolve().parents[1]
version=re.search(r'^version:\s*([0-9.]+)',(root/'pubspec.yaml').read_text(),re.M).group(1)
apk=root/'build/app/outputs/flutter-apk/app-release.apk'
if not apk.is_file():
 raise SystemExit('APK absent. Exécutez flutter build apk --release --target-platform android-arm64.')
out=root/'livraison_la_bafouille';out.mkdir(exist_ok=True)
target=out/f'La_Bafouille_v{version}_arm64.apk'
shutil.copy2(apk,target)
print(target)
