# PROMPT CODEX — LA BAFOUILLE
## Application Flutter de rédaction, correction et correspondance avec agent IA

### 1. TON RÔLE

Tu es Codex, un développeur Flutter/Dart senior, architecte logiciel, designer UI/UX, expert en intelligence artificielle et spécialiste du développement Android et Linux.

Tu dois créer une application complète appelée :

# LA BAFOUILLE
**« Tu racontes, La Bafouille rédige ! »**

Il s'agit d'un atelier intelligent de rédaction, de correction orthographique et grammaticale, de reformulation et d'apprentissage du français.

L'application doit être utilisable par des particuliers, des professionnels, des étudiants et toute personne souhaitant améliorer ses correspondances.

**IMPORTANT : Je veux une véritable application fonctionnelle et livrable, pas une maquette ou une démonstration.**

---

# 2. CONSIGNES DE TRAVAIL AUTONOME

Tu dois travailler avec un maximum d'autonomie.

- Communique exclusivement en français.
- Ne me pose pas de questions inutiles.
- Prends seul les décisions techniques courantes.
- Ne demande pas de confirmation à chaque modification.
- Analyse les erreurs et corrige-les automatiquement.
- Exécute les tests nécessaires.
- Continue le développement après chaque étape réussie.
- Documente les décisions importantes.
- N'utilise pas de fonctionnalités fictives.
- N'annonce jamais une compilation réussie sans l'avoir exécutée.
- Ne supprime pas de fichiers importants sans autorisation.
- N'exécute aucune commande destructive sans validation.
- Ne publie rien sur Internet sans autorisation.
- Ne dépense aucun crédit API sans configuration et accord préalable.

Si une difficulté apparaît, cherche une solution technique avant de solliciter mon intervention.

Respecte les autorisations et restrictions de ton environnement d'exécution.

**Travaille jusqu'à obtenir une application complète, testée et livrable, dans les limites de l'environnement disponible.**

---

# 3. TECHNOLOGIES

Utiliser :

- Flutter stable.
- Dart.
- Material Design 3 personnalisé.
- Riverpod pour la gestion d'état.
- GoRouter pour la navigation.
- SQLite ou autre stockage local fiable.
- Architecture modulaire.
- Services IA indépendants de l'interface.
- Tests unitaires, widgets et intégration.

Plateformes :

**Android**
- APK ARM64.
- Interface responsive.
- Gestion des permissions.
- Partage de documents.

**Linux**
- Compatible Ubuntu et Lubuntu.
- Exécutable natif.
- Paquet DEB.
- Interface adaptée aux grandes fenêtres.

Prévoir une architecture permettant d'ajouter Windows ultérieurement.

---

# 4. DESIGN ORIGINAL

Créer une interface très originale dans un univers :

**Atelier d'écriture rétro-futuriste et laboratoire des mots.**

L'application doit avoir une personnalité visuelle forte.

### Palette graphique

- Violet profond : `#482878`
- Turquoise : `#25C4C0`
- Corail : `#FF7666`
- Jaune : `#FFD166`
- Crème : `#FFF7E8`
- Bleu nuit : `#242438`

### Identité visuelle

Créer un petit assistant animé nommé **Bafou**.

Bafou est un personnage sympathique et légèrement loufoque, mélange de robot secrétaire, plume et machine à écrire.

Prévoir :

- Animations fluides.
- Cartes avec dégradés.
- Effets de transparence.
- Icônes originales.
- Transitions soignées.
- Mode clair et sombre.
- Typographie lisible.
- Accessibilité.
- Adaptation smartphone et ordinateur.

Les animations ne doivent pas ralentir l'application.

---

# 5. ÉCRAN D'ACCUEIL

Créer un tableau de bord comprenant :

1. ✉️ Nouveau courrier
2. ✍️ Correction et orthographe
3. 🤖 Discuter avec Bafou
4. 🎭 Laboratoire des styles
5. 📚 Dictionnaire et conjugaison
6. 📂 Mes correspondances
7. 📝 Mes brouillons
8. 📖 Modèles de courriers
9. ⚙️ Paramètres

Ajouter une grande zone de saisie :

**« Qu'est-ce qu'on écrit aujourd'hui ? »**

L'utilisateur peut écrire ou dicter sa demande.

---

# 6. AGENT IA DE RÉDACTION

Créer un véritable assistant conversationnel.

Exemple utilisateur :

« Je voudrais écrire à mon propriétaire parce qu'il ne répare pas mon chauffage. Cela fait trois semaines. Je voudrais être poli, mais assez ferme. »

L'agent doit :

1. Comprendre la situation.
2. Identifier le destinataire.
3. Déterminer le type de courrier.
4. Identifier les informations manquantes.
5. Poser uniquement les questions indispensables.
6. Proposer plusieurs styles.
7. Générer un courrier structuré.
8. Permettre sa modification.
9. Enregistrer le document.
10. Proposer son export.

### Catégories de correspondances

- Courriers administratifs.
- Réclamations.
- Lettres professionnelles.
- Lettres personnelles.
- Demandes de remboursement.
- Courriers aux assurances.
- Courriers aux banques.
- Courriers aux propriétaires.
- Lettres de motivation.
- Candidatures spontanées.
- Résiliations.
- Invitations.
- Remerciements.
- Excuses.
- Félicitations.
- Courriels professionnels.
- Correspondances libres.

Prévoir des modèles personnalisables.

L'IA ne doit jamais inventer des faits personnels, des montants, des dates ou des références juridiques.

---

# 7. LABORATOIRE DES STYLES

L'utilisateur doit pouvoir demander plusieurs versions du même courrier.

Styles disponibles :

- Simple.
- Naturel.
- Familier.
- Amical.
- Chaleureux.
- Diplomatique.
- Formel.
- Professionnel.
- Administratif.
- Soutenu.
- Ferme.
- Très ferme.
- Humoristique.
- Sarcastique.
- Élégant.
- Concis.
- Détaillé.

Permettre de combiner plusieurs styles.

Exemple :

« Je veux un courrier professionnel, diplomatique, mais avec une touche de fermeté. »

### Comparateur

Afficher jusqu'à trois propositions.

L'utilisateur peut :

- Comparer les versions.
- Sélectionner sa préférée.
- Fusionner des passages.
- Modifier un paragraphe.
- Demander une nouvelle proposition.
- Revenir à une version précédente.

Créer un historique des versions.

---

# 8. PAGE CORRECTION ET ORTHOGRAPHE

Créer une page indépendante intitulée :

## LE LABO DES MOTS

L'utilisateur peut écrire un mot, une phrase, un paragraphe ou un texte complet.

Exemples :

« Comment écrit-on : je vous est envoyé ? »

« Quelle différence entre ces et ses ? »

« Est-ce que cette phrase est correcte ? »

« Corrige mon texte sans changer mon style. »

### Fonctionnalités

- Correction orthographique.
- Correction grammaticale.
- Conjugaison.
- Ponctuation.
- Syntaxe.
- Accords.
- Homophones.
- Reformulation.
- Détection des répétitions.
- Amélioration de la lisibilité.

### Correction pédagogique

Afficher :

**Texte original**

« Je vous est envoyé les documents hier. »

**Texte corrigé**

« Je vous ai envoyé les documents hier. »

**Explication**

Le verbe avoir se conjugue « j'ai » à la première personne du singulier.

Ajouter :

- Explication simple.
- Explication détaillée.
- Exemples.
- Règle grammaticale.
- Mini-exercice facultatif.

Permettre d'accepter ou refuser chaque correction.

Conserver systématiquement le texte original.

Ne jamais remplacer automatiquement le contenu sans possibilité d'annulation.

---

# 9. DICTIONNAIRE INTELLIGENT

Créer une rubrique linguistique avec :

- Définitions.
- Synonymes.
- Antonymes.
- Conjugaison.
- Homophones.
- Expressions françaises.
- Formules de politesse.
- Vocabulaire administratif.
- Vocabulaire professionnel.
- Expressions à éviter.

L'utilisateur doit pouvoir demander :

« Trouve un mot plus élégant que problème. »

« Comment conjuguer acquérir au subjonctif ? »

« Quelle formule utiliser pour terminer une lettre au préfet ? »

Prévoir un historique des recherches.

---

# 10. CONVERSATION AVEC BAFOU

Créer un chat IA intégré.

Bafou doit comprendre le contexte du document en cours.

Exemples :

- « Raccourcis le deuxième paragraphe. »
- « Rends cette phrase moins agressive. »
- « Ajoute une conclusion. »
- « Explique pourquoi tu as choisi ce mot. »
- « Réécris le courrier en langage simple. »
- « Garde le texte mais corrige les fautes. »

L'utilisateur doit pouvoir accepter ou refuser les modifications proposées.

Ne pas modifier directement un document sans afficher les changements.

---

# 11. FOURNISSEURS IA

Prévoir plusieurs fournisseurs :

1. OpenAI.
2. Anthropic Claude.
3. Google Gemini.
4. Mistral.
5. Ollama local.

Créer une architecture permettant d'ajouter d'autres fournisseurs.

### Configuration

Créer une page permettant de :

- Choisir le fournisseur.
- Ajouter une clé API.
- Sélectionner un modèle compatible.
- Tester la connexion.
- Modifier les paramètres.
- Voir les erreurs.
- Connaître le fournisseur actif.

Ne jamais stocker les clés API en clair dans les préférences ordinaires.

Utiliser un stockage sécurisé compatible avec chaque plateforme.

Ne jamais afficher les clés complètes dans les journaux.

L'application doit démarrer et rester utilisable sans clé API.

Les fonctionnalités nécessitant l'IA doivent expliquer clairement pourquoi elles sont indisponibles.

---

# 12. ÉDITEUR DE COURRIER

Créer un véritable éditeur de documents.

Fonctionnalités :

- Saisie libre.
- Copier-coller.
- Gras.
- Italique.
- Souligné.
- Alignement.
- Paragraphes.
- Listes.
- Annuler et rétablir.
- Rechercher et remplacer.
- Enregistrement automatique.
- Historique des versions.

### Structure d'une lettre française

Prévoir :

- Coordonnées de l'expéditeur.
- Coordonnées du destinataire.
- Ville et date.
- Objet.
- Références éventuelles.
- Formule d'appel.
- Corps du courrier.
- Formule de politesse.
- Signature.
- Pièces jointes.

Prévoir des modèles A4 professionnels.

---

# 13. EXPORTS ET SAUVEGARDES

L'application doit exporter les documents en :

- PDF.
- DOCX.
- TXT.
- HTML.

Prévoir également :

- Impression.
- Partage.
- Copie dans le presse-papiers.
- Ouverture dans une application de messagerie.
- Sauvegarde locale.
- Restauration.
- Export de la bibliothèque.

### Sauvegardes

Créer un système de sauvegarde des documents et paramètres non sensibles.

Prévoir une procédure de restauration en cas de réinstallation.

Les clés API ne doivent pas être incluses dans une sauvegarde non chiffrée.

---

# 14. DICTÉE VOCALE

Ajouter une fonction microphone.

L'utilisateur explique oralement ce qu'il souhaite écrire.

L'application doit :

1. Enregistrer la demande vocale avec autorisation.
2. Effectuer une transcription.
3. Afficher le texte.
4. Permettre sa correction.
5. Transmettre le texte à l'agent IA après validation.

Ajouter une fonction de lecture vocale des courriers.

Gérer les différences techniques entre Android et Linux.

---

# 15. MODÈLES DE CORRESPONDANCES

Créer au minimum 50 modèles de courriers réellement utilisables.

Catégories :

- Administration.
- Travail.
- Banque.
- Assurance.
- Logement.
- Consommation.
- Famille.
- Associations.
- Vie quotidienne.

Chaque modèle doit comporter des champs personnalisables.

Ne jamais utiliser de coordonnées personnelles fictives comme s'il s'agissait de données réelles.

---

# 16. HISTORIQUE ET BIBLIOTHÈQUE

Créer une bibliothèque locale.

Fonctionnalités :

- Liste des documents.
- Recherche.
- Filtres.
- Catégories.
- Favoris.
- Brouillons.
- Documents terminés.
- Duplication.
- Renommage.
- Suppression.
- Restauration après suppression accidentelle lorsque possible.

Prévoir des sauvegardes automatiques.

---

# 17. MODE D'EMPLOI

Créer un guide intégré en français.

Expliquer :

- Comment rédiger un courrier.
- Comment utiliser Bafou.
- Comment choisir un style.
- Comment corriger une phrase.
- Comment exporter un PDF.
- Comment enregistrer un document.
- Comment configurer une IA.
- Comment effectuer une sauvegarde.

Ajouter un tutoriel au premier lancement.

---

# 18. SÉCURITÉ ET CONFIDENTIALITÉ

L'application manipule des correspondances personnelles.

Respecter les principes suivants :

- Stockage local par défaut.
- Aucune transmission automatique de documents.
- Consentement avant utilisation d'une IA distante.
- Gestion sécurisée des clés API.
- Aucune clé dans le code source.
- Aucune donnée sensible dans les journaux.
- Possibilité de supprimer les documents.
- Sauvegardes sécurisées.
- Gestion des erreurs réseau.
- Protection contre les réponses IA malformées.

Ne jamais présenter un courrier généré comme un conseil juridique professionnel.

---

# 19. TESTS OBLIGATOIRES

Créer et exécuter les tests nécessaires.

Tester :

1. Démarrage de l'application.
2. Navigation.
3. Création d'un courrier.
4. Modification d'un courrier.
5. Enregistrement.
6. Réouverture d'un brouillon.
7. Correction orthographique.
8. Acceptation des corrections.
9. Refus des corrections.
10. Génération IA.
11. Gestion des erreurs API.
12. Changement de fournisseur.
13. Export PDF.
14. Export DOCX.
15. Sauvegarde et restauration.
16. Fonctionnement sans connexion.
17. Affichage Android.
18. Affichage Linux.

Exécuter notamment :

`flutter analyze`

`flutter test`

Corriger les erreurs détectées.

Ne pas masquer les échecs.

---

# 20. LIVRAISON COMPLÈTE

Créer un dossier :

`livraison_la_bafouille/`

Il doit contenir :

### Android

`La_Bafouille_v1.0.0_arm64.apk`

### Linux

`la-bafouille_1.0.0_amd64.deb`

### Code source

`La_Bafouille_v1.0.0_source.zip`

### Documentation

- README.md
- INSTALLATION.md
- GUIDE_UTILISATEUR.md
- CHANGELOG.md
- RAPPORT_TESTS.md

### Vérifications

- APK correspondant au projet actuel.
- Application Android installable.
- Application Linux exécutable.
- Paquet DEB correctement construit.
- Code source complet.
- Aucune clé API dans les livrables.
- Documentation en français.

Si la compilation est impossible dans l'environnement, expliquer précisément pourquoi et fournir les commandes nécessaires.

Ne jamais recycler un ancien APK.

---

# 21. PLAN DE DÉVELOPPEMENT

Organiser le travail en six phases.

### PHASE 1 — FONDATIONS

- Création du projet Flutter.
- Architecture.
- Navigation.
- Design.
- Personnage Bafou.
- Stockage local.
- Écran d'accueil.

### PHASE 2 — CORRESPONDANCES

- Éditeur.
- Modèles.
- Brouillons.
- Historique.
- Sauvegarde.

### PHASE 3 — AGENT IA

- Fournisseurs IA.
- Configuration.
- Génération.
- Conversation.
- Styles.
- Comparateur.

### PHASE 4 — CORRECTION

- Correcteur.
- Explications.
- Dictionnaire.
- Conjugaison.
- Exercices.

### PHASE 5 — FONCTIONS AVANCÉES

- Dictée.
- Lecture vocale.
- Exports.
- Sauvegardes.
- Mode d'emploi.

### PHASE 6 — FINALISATION

- Audit.
- Tests.
- Correction des bugs.
- Optimisation.
- Compilation.
- Packaging.
- Documentation.

---

# 22. INSTRUCTIONS FINALES À CODEX

Tu dois réaliser ce projet avec sérieux et autonomie.

Ne te contente pas de créer les écrans.

Chaque bouton doit déclencher une véritable fonctionnalité.

Chaque document doit pouvoir être enregistré et retrouvé.

Chaque correction doit être compréhensible.

Chaque fonction IA doit gérer correctement les erreurs.

Le design doit être original, coloré, moderne et cohérent.

### AUTONOMIE

Je souhaite pouvoir te laisser travailler pendant que je fais autre chose.

Ne m'interromps pas pour des décisions techniques ordinaires.

Enchaîne les phases automatiquement.

Exécute les tests après chaque étape.

Corrige les problèmes avant de continuer.

Tu peux utiliser les outils et commandes autorisés dans ton environnement, sans chercher à contourner les protections ou les confirmations de sécurité.

### RAPPORT FINAL

À la fin, fournis un rapport en français indiquant :

- Les fonctionnalités développées.
- Les fonctionnalités réellement testées.
- Les éventuelles limitations.
- Les résultats des compilations.
- Les emplacements des fichiers livrables.
- Les instructions d'installation.

### OBJECTIF FINAL

Créer **LA BAFOUILLE**, une application Flutter professionnelle de rédaction et de correction avec agent IA.

Elle doit être agréable, intuitive, pédagogique, originale et véritablement utilisable.

**Commence immédiatement par analyser l'environnement, créer le projet si nécessaire, puis réalise toutes les phases dans l'ordre jusqu'à la livraison finale.**