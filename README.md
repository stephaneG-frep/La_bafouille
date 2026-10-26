# La Bafouille

**« Tu racontes, La Bafouille rédige ! »**

La Bafouille est un atelier Flutter en français pour écrire et retrouver des
courriers. Les documents sont conservés localement. Les fonctions d'intelligence
artificielle sont facultatives et chaque envoi demande une confirmation.

## Fonctions

- Bibliothèque locale avec recherche, filtres, favoris, corbeille, versions et
  sauvegarde/restauration JSON.
- Éditeur avec sauvegarde automatique, mise en forme légère, impression et
  exports PDF, DOCX, HTML et TXT.
- 54 modèles, correction locale pédagogique, fiches linguistiques et historique
  des recherches.
- Assistant IA configurable (OpenAI, Anthropic, Gemini, Mistral, Grok,
  Perplexity ou Ollama) avec consentement avant chaque envoi.
- Dictée Android avec aperçu avant insertion et lecture vocale.
- Interface responsive Android et Linux, en français, avec mode clair et sombre.

## Démarrage développeur

Prérequis : Flutter stable (Dart 3.9 ou ultérieur), ainsi que les outils
spécifiques à la plateforme visée.

```sh
flutter pub get
flutter analyze
flutter test
flutter run -d linux
```

Pour Android, configurez un appareil ou un émulateur puis lancez
`flutter run`. L'application reste utilisable sans configuration IA.

## Fournisseurs IA et confidentialité

Configurez un fournisseur, un modèle et, si nécessaire, une clé dans
**Paramètres**. Les clés sont stockées avec `flutter_secure_storage` et ne sont
pas incluses dans les sauvegardes JSON. L'application affiche un consentement
avant chaque transmission. Un appel distant peut être facturé par le fournisseur.

Sous Android, le HTTP en clair est désactivé par défaut. L'exception limitée à
`localhost` et `10.0.2.2` permet l'utilisation d'Ollama local dans les cas
prévus ; utilisez HTTPS pour un serveur accessible sur un autre hôte.

## Documentation et livraison

- [Installation](INSTALLATION.md)
- [Guide utilisateur](GUIDE_UTILISATEUR.md)
- [Historique des changements](CHANGELOG.md)
- [Rapport de tests et de livraison](RAPPORT_TESTS.md)

Les fichiers générés sont placés dans `livraison_la_bafouille/`. La procédure
complète de génération est décrite dans [INSTALLATION.md](INSTALLATION.md).
