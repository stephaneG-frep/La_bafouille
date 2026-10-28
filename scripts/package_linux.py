#!/usr/bin/env python3
"""Construit un DEB à partir du bundle Flutter courant, sans installer le paquet."""
from pathlib import Path
import re, shutil, subprocess, tempfile
root=Path(__file__).resolve().parents[1]
version=re.search(r'^version:\s*([0-9.]+)',(root/'pubspec.yaml').read_text(),re.M).group(1)
bundle=root/'build/linux/x64/release/bundle'
if not (bundle/'la_bafouille').is_file():
 raise SystemExit('Bundle absent. Exécutez flutter build linux --release.')
output=root/'livraison_la_bafouille';output.mkdir(exist_ok=True)
with tempfile.TemporaryDirectory(prefix='bafouille_deb_') as tmp:
 package=Path(tmp)
 shutil.copytree(bundle,package/'opt/la-bafouille')
 (package/'DEBIAN').mkdir()
 (package/'DEBIAN/control').write_text(f'''Package: la-bafouille
Version: {version}
Section: editors
Priority: optional
Architecture: amd64
Maintainer: Projet La Bafouille <contact@localhost>
Depends: libgtk-3-0, libstdc++6, libsecret-1-0, libjsoncpp25, libblkid1, liblzma5
Recommends: gnome-keyring, espeak-ng
Description: Atelier francais de redaction et de correspondance
 Documents locaux, modeles, correction pedagogique et assistants IA configurables.
''')
 (package/'usr/bin').mkdir(parents=True)
 launcher=package/'usr/bin/la-bafouille';launcher.write_text('#!/bin/sh\nexec /opt/la-bafouille/la_bafouille "$@"\n');launcher.chmod(0o755)
 (package/'usr/share/applications').mkdir(parents=True)
 (package/'usr/share/applications/la-bafouille.desktop').write_text('''[Desktop Entry]
Type=Application
Name=La Bafouille
Comment=Tu racontes, La Bafouille rédige !
Exec=la-bafouille
Icon=la-bafouille
Terminal=false
Categories=Office;WordProcessor;
StartupWMClass=fr.labafouille.la_bafouille
''')
 (package/'usr/share/icons/hicolor/scalable/apps').mkdir(parents=True)
 shutil.copy(root/'assets/la-bafouille.svg',package/'usr/share/icons/hicolor/scalable/apps/la-bafouille.svg')
 subprocess.run(['dpkg-deb','--root-owner-group','--build',str(package),str(output/f'la-bafouille_{version}_amd64.deb')],check=True)
