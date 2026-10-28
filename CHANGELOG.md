# Historique des changements

## 1.0.2

- Correction : une sauvegarde JSON malformée ne bloque plus les
  enregistrements suivants ; elle est rejetée dès sa lecture.
- Restauration : l'adresse du serveur Ollama n'est plus importée, et elle est
  affichée dans le dialogue de consentement.
- Bibliothèque : suppression définitive, vidage de la corbeille (copie de
  secours comprise), filtre par catégorie ; catégorie modifiable dans l'éditeur.
- Dictée : transcription en direct et relecture, insertion au curseur, dictée
  de la demande depuis l'accueil (envoyée à Bafou après validation) et dans
  Bafou. Les écouteurs du service vocal ne restent plus liés à un écran fermé.
- Nouveau courrier : squelette de lettre française à compléter.
- Accueil : nombre de courriers correctement accordé ; version centralisée
  dans `pubspec.yaml` (scripts de livraison et écran Paramètres).
- Laboratoire des styles : comparateur côte à côte sur grand écran, retouche
  manuelle et nouvelle proposition pour chaque version.
- Labo des mots : 24 règles locales (homophones, conjugaison, ponctuation,
  répétitions), explication détaillée pour chaque correction, cinq
  mini-exercices ; les corrections ne se chevauchent plus.
- Mémento linguistique : 81 fiches en 8 rubriques (conjugaison, homophones,
  synonymes, formules de politesse, vocabulaire administratif et
  professionnel, expressions), filtres par rubrique et recherche tolérante
  aux accents qui comprend des questions entières.
- Linux : l'éditeur ouvre la messagerie par défaut avec l'objet et le texte
  préremplis ; le partage Android transmet le texte sans balises.
- Android : signature de publication via `android/key.properties`, avec
  repli sur la clé debug si le fichier est absent.
- Design : Bafou redessiné et animé, fond d'atelier, tuiles en dégradé,
  cartes translucides, transitions entre pages ; animations désactivées si le
  système demande de les réduire.

## 1.0.1

- Ajout des fournisseurs IA Grok (xAI) et Perplexity avec leurs endpoints
  respectifs.
- Indications de configuration des modèles mises à jour.

## 1.0.0

- Première version de l'atelier de rédaction Flutter pour Android et Linux.
- Bibliothèque locale, modèles, éditeur, historique et sauvegardes JSON.
- Exports PDF, DOCX, TXT et HTML, impression et partage Android.
- Assistant IA configurable avec fournisseurs OpenAI, Anthropic, Gemini,
  Mistral et Ollama, et consentement à chaque envoi.
- Correction locale pédagogique, fiches linguistiques, dictée Android et
  lecture vocale.
- HTTP en clair restreint sur Android à l'hôte local et à la passerelle
  d'émulateur `10.0.2.2`.
