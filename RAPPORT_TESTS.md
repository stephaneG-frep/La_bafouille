# Rapport de tests et de livraison

Ce rapport décrit les vérifications exécutées pour la livraison présente.

## Vérifications automatisées

| Vérification | Résultat |
|---|---|
| `flutter analyze` | Réussi après les changements : aucun problème détecté. |
| `flutter test` | Réussi après les changements : tous les tests passent. |
| `flutter test integration_test/app_test.dart -d linux` | Réussi : démarrage natif Linux et ouverture de la bibliothèque. |
| Adaptateurs IA | Tests simulés pour chaque fournisseur, incluant le Bearer et les endpoints Grok et Perplexity. |
| `flutter build apk --release --target-platform android-arm64` | Réussi ; APK ARM64 généré (22,1 Mo). |
| Signature APK | Vérifiée par `apksigner` (schéma v2) ; certificat debug Android. |
| `flutter build linux --release` | Réussi ; bundle Linux x64 généré. |
| `python3 scripts/package_linux.py` | Réussi ; paquet DEB généré et métadonnées vérifiées. |
| `python3 scripts/package_source.py` | Réussi ; archive source générée avec les documents de livraison. |
| Bundle Linux natif | `ldd` ne signale aucune dépendance manquante. |
| Installation sur le Honor MTN-NX1 | Réussie ; version 1.0.1 lancée, activité principale au premier plan. |
| Fournisseurs IA réels | Non testés ; les appels réels exigent des clés et peuvent être facturés. |

## Portée

Les tests Flutter couvrent les modèles, stockage et restauration, corrections
locales, exports, modèles de courrier, adaptateurs IA simulés et quelques
parcours widgets. Ils ne remplacent pas un essai d'installation sur chaque
version Android ou distribution Linux cible. La version 1.0.1 a également été
installée et lancée sur un téléphone Honor ; aucun appel IA réel n'a été effectué.

La compilation Android a d'abord échoué sur la validation de la configuration
de sécurité réseau (attribut `includeSubdomains` requis par Lint). La
configuration a été corrigée, puis la compilation release a réussi.

## Signature Android

Le build release actuel utilise la signature debug définie dans la
configuration Gradle du projet. Il est destiné à l'installation locale, pas à
une publication sur un magasin d'applications.

## Artefacts

Artefacts générés :

- APK ARM64 : `livraison_la_bafouille/La_Bafouille_v1.0.1_arm64.apk`
- Paquet Linux : `livraison_la_bafouille/la-bafouille_1.0.1_amd64.deb`
- Archive source : `livraison_la_bafouille/La_Bafouille_v1.0.1_source.zip`

Le DEB annonce l'architecture `amd64` et contient l'exécutable, les assets et
les bibliothèques Flutter. L'APK embarque les bibliothèques ARM64 nécessaires.
