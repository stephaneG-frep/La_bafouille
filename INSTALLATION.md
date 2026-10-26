# Installation et compilation

## Prérequis de compilation

- Flutter stable et Dart 3.9 ou ultérieur.
- Android : Android SDK, licences Android acceptées et JDK compatible avec
  Android Gradle Plugin.
- Linux : Ubuntu/Lubuntu avec CMake, Ninja, GTK 3, `dpkg-deb` et les dépendances
  natives Flutter.

Récupérez les dépendances et vérifiez le projet :

```sh
flutter pub get
flutter analyze
flutter test
```

## Android ARM64

Depuis la racine du projet :

```sh
flutter build apk --release --target-platform android-arm64
```

L'APK Flutter est généré dans
`build/app/outputs/flutter-apk/app-release.apk`. La configuration de
ce projet signe le build release avec la clé debug Flutter par défaut : ce
fichier convient à une installation locale/sideload, mais **pas à une
publication Play Store**. Pour une publication, configurez une clé de
signature privée qui ne doit pas être ajoutée au dépôt ni à l'archive source.

## Linux et paquet DEB

```sh
flutter build linux --release
python3 scripts/package_linux.py
```

Le paquet est créé sous
`livraison_la_bafouille/la-bafouille_1.0.1_amd64.deb`. Il cible Ubuntu/Debian
64 bits et dépend notamment des bibliothèques GTK 3 et libsecret. Installez-le
avec :

```sh
sudo apt install ./livraison_la_bafouille/la-bafouille_1.0.1_amd64.deb
```

Ou, sans installer le paquet, exécutez le bundle après compilation :

```sh
build/linux/x64/release/bundle/la_bafouille
```

## Archive source

```sh
python3 scripts/package_source.py
```

L'archive source exclut les caches de build, les paramètres locaux et les
fichiers de clés usuels.

## Récupération de la bibliothèque

La bibliothèque se trouve dans le dossier de support d'application de la
plateforme, dans le sous-dossier `atelier/`. Dans les paramètres de
l'application, exportez régulièrement une sauvegarde JSON vers un emplacement
sûr. Elle contient les textes en clair. Après réinstallation, utilisez
**Paramètres → Restaurer une sauvegarde** ; les documents restaurés sont ajoutés
comme copies et ne remplacent pas ceux déjà présents.

En cas de fichier principal illisible, ne le supprimez pas. La sauvegarde
automatique précédente est nommée `bibliotheque.precedente.json` dans le même
dossier. Copiez-la vers un emplacement sûr et utilisez la fonction de
restauration de l'application lorsque cela est possible.

## Ollama

- Linux : saisissez l'adresse de votre serveur Ollama, par exemple
  `http://localhost:11434`.
- Émulateur Android : utilisez `http://10.0.2.2:11434`.
- Appareil Android physique : configurez un endpoint HTTPS ; Android bloque les
  connexions HTTP en clair vers les autres hôtes.

## Limites de vérification

La compilation produit un paquet installable, mais l'installation sur un
téléphone physique et l'exécution sur une distribution Linux différente doivent
être vérifiées sur les appareils cibles. Les accès aux fournisseurs IA réels
nécessitent vos propres identifiants et ne sont pas testés par les tests
automatisés.
