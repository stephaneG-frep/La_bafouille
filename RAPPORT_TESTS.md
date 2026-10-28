# Rapport de tests et de livraison

Ce rapport décrit les vérifications exécutées pour la livraison 1.0.2.

## Vérifications automatisées

| Vérification | Résultat |
|---|---|
| `flutter analyze` | Réussi : aucun problème détecté. |
| `flutter test` | Réussi : 30 tests passent (unitaires et widgets, écrans de 412 et 1440 px). |
| `flutter test integration_test/app_test.dart -d linux` | Non relancé pour la 1.0.2 : ce test démarre l'application réelle sur la bibliothèque du poste. Dernier passage réussi en 1.0.1. |
| Adaptateurs IA | Tests simulés pour chaque fournisseur, incluant le Bearer et les endpoints Grok et Perplexity. |
| `flutter build apk --release --target-platform android-arm64` | Réussi ; APK ARM64 généré (21,2 Mo), versionCode 3, versionName 1.0.2. |
| Signature APK | Vérifiée par `apksigner` (schéma v2) ; certificat debug Android, faute de `android/key.properties`. |
| `flutter build linux --release` | Réussi ; bundle Linux x64 généré. |
| `python3 scripts/package_android.py` | Réussi ; APK copié dans la livraison. |
| `python3 scripts/package_linux.py` | Réussi ; paquet DEB généré, métadonnées `la-bafouille` 1.0.2 `amd64` vérifiées. |
| `python3 scripts/package_source.py` | Réussi ; archive générée, sans `key.properties`, magasin de clés ni clé API détectée. |
| Bundle Linux natif | `ldd` ne signale aucune dépendance manquante. |
| Installation sur le Honor MTN-NX1 | Réussie par mise à jour (`adb install -r`), bibliothèque existante conservée ; version 1.0.2 lancée, activité principale au premier plan, aucune erreur fatale dans les journaux. |
| Fournisseurs IA réels | Non testés ; les appels réels exigent des clés et peuvent être facturés. |

## Nouveautés couvertes par des tests

- Rejet des sauvegardes JSON malformées sans blocage des enregistrements
  suivants ; l'adresse Ollama n'est pas importée lors d'une restauration.
- Suppression définitive, y compris dans la copie de secours automatique.
- Correcteur local enrichi : corrections attendues, phrases correctes laissées
  intactes, absence de chevauchement, explication détaillée pour chaque règle.
- Mémento : validité des 81 fiches et des 8 rubriques, réponses aux questions
  d'exemple du cahier des charges (problème, acquérir au subjonctif, préfet).
- Squelette de lettre française du nouveau courrier.
- Version affichée identique à celle de `pubspec.yaml`.

## Non testé automatiquement

- **Dictée vocale** (accueil, Bafou, éditeur) : dépend du service de
  reconnaissance Android ; à vérifier manuellement sur l'appareil.
- **Envoi par courriel sous Linux** : ouvre la messagerie par défaut via
  `xdg-open` ; non déclenché pendant les tests.
- **Comparateur des styles** : l'affichage côte à côte, la retouche et la
  régénération nécessitent des réponses d'un fournisseur IA réel.

## Portée

Les tests Flutter couvrent les modèles, stockage et restauration, corrections
locales, mémento, exports, modèles de courrier, adaptateurs IA simulés et
quelques parcours widgets. Ils ne remplacent pas un essai d'installation sur
chaque version Android ou distribution Linux cible. Aucun appel IA réel n'a
été effectué.

## Signature Android

Le build release est signé avec la clé debug tant que `android/key.properties`
n'existe pas. Il est destiné à l'installation locale, pas à une publication.
La procédure de signature avec une clé privée est décrite dans
[INSTALLATION.md](INSTALLATION.md) ; changer de clé impose de désinstaller
l'application, donc d'exporter la bibliothèque au préalable.

## Artefacts

Artefacts générés :

- APK ARM64 : `livraison_la_bafouille/La_Bafouille_v1.0.2_arm64.apk`
- Paquet Linux : `livraison_la_bafouille/la-bafouille_1.0.2_amd64.deb`
- Archive source : `livraison_la_bafouille/La_Bafouille_v1.0.2_source.zip`

Le DEB annonce l'architecture `amd64` et contient l'exécutable, les assets et
les bibliothèques Flutter. L'APK embarque les bibliothèques ARM64 nécessaires.
