# Guide utilisateur

## Créer et retrouver un courrier

Depuis l'accueil, choisissez **Nouveau courrier** (une lettre structurée :
expéditeur, destinataire, lieu et date, objet, formule d'appel, corps, formule
de politesse, signature, pièces jointes) ou ouvrez **Modèles**.
Remplacez les champs entre crochets par vos informations, puis rédigez dans
l'éditeur. Les changements sont enregistrés après une courte pause ; le statut
de l'éditeur indique si l'enregistrement a abouti. La bibliothèque permet de
rechercher, filtrer, marquer comme favori, dupliquer et déplacer un courrier
dans la corbeille. Un document supprimé de cette façon peut être restauré.
Depuis la corbeille, **Supprimer définitivement** ou **Vider la corbeille**
efface le document de l'appareil, y compris de la copie de secours
automatique ; cette action est irréversible. La catégorie d'un courrier se
choisit dans l'éditeur et sert de filtre dans la bibliothèque.

Le statut **Terminé** est un repère personnel : il n'envoie pas le courrier.

## Bafou et les styles

Configurez un fournisseur et un modèle dans **Paramètres**. Ajoutez une clé
uniquement pour les fournisseurs qui en demandent une. À chaque envoi, relisez
le nom du fournisseur et le contexte, puis confirmez explicitement. Seuls les
textes nécessaires à cette demande sont transmis ; un service distant peut
conserver ses propres données selon ses conditions d'utilisation.

Les fournisseurs distants proposés sont OpenAI, Anthropic, Gemini, Mistral,
Grok (xAI) et Perplexity. Le nom du modèle doit être celui auquel votre compte
fournisseur donne accès. Ollama permet d'utiliser un modèle installé sur votre
serveur local.

Les styles sélectionnés sont combinables. Le laboratoire peut demander une,
deux ou trois propositions ; chaque proposition peut entraîner un appel IA
distinct. Une proposition n'est appliquée qu'après votre choix et, pour un
document existant, une comparaison avec le texte actuel.

## Corriger et apprendre

Le labo des mots détecte localement quelques erreurs courantes. Cochez les
suggestions que vous acceptez ; le texte source reste conservé. Le correcteur
local est limité et ne garantit pas l'absence de fautes. L'analyse approfondie
utilise l'IA configurée et demande un consentement avant l'envoi.

Le cabinet linguistique propose des fiches hors ligne. Vous pouvez consulter
Bafou pour une recherche plus détaillée, après confirmation de transmission.

## Éditer et exporter

L'éditeur propose gras (`**texte**`), italique (`*texte*`), souligné
(`<u>texte</u>`), alignement, listes, recherche/remplacement, annulation,
rétablissement et historique des versions. Exportez en PDF, DOCX, TXT ou HTML,
imprimez le document ou copiez son texte. Le PDF est mis en page au format A4.
Sur Android, l'icône de partage envoie le texte vers une application installée.
Sur Linux, l'icône d'enveloppe ouvre votre messagerie par défaut avec l'objet
et le texte préremplis ; pour envoyer un PDF, exportez-le puis joignez-le.

Sur Android, le microphone demande une autorisation et affiche la transcription
en direct ; vous la corrigez avant de la valider. Dans l'éditeur, le texte est
inséré au curseur. Sur l'accueil, **Dicter ma demande** transmet la demande
validée à Bafou, toujours après le dialogue de consentement. Dans Bafou, le
bouton **Dicter** complète votre demande. La lecture vocale utilise la voix disponible
sur l'appareil. Sur Linux, la lecture nécessite `espeak-ng` ; la dictée intégrée
n'est pas disponible.

## Sauvegarder

Dans **Paramètres**, exportez la bibliothèque JSON sur un support distinct.
Cette sauvegarde n'est pas chiffrée : elle contient vos documents et réglages
non sensibles, mais aucune clé API. Lors d'une restauration, les courriers sont
ajoutés comme copies afin de préserver la bibliothèque actuelle.

## Confidentialité et prudence

Les documents sont conservés localement par défaut. Les clés IA sont conservées
dans le coffre sécurisé de la plateforme. Ne transmettez pas d'informations que
vous ne souhaitez pas communiquer au fournisseur choisi. Vérifiez toujours les
faits, dates, montants, coordonnées et références générés. Un courrier proposé
par l'IA ne constitue pas un conseil juridique professionnel.

## Le mémento linguistique

**Dictionnaire et conjugaison** propose 81 fiches hors ligne, classées en huit
rubriques : conjugaison, homophones, définitions et synonymes, formules de
politesse, vocabulaire administratif, vocabulaire professionnel, expressions
françaises et expressions à éviter. Vous pouvez taper un mot ou une question
entière (« acquérir au subjonctif », « formule pour une lettre au préfet ») ; la
fiche la plus pertinente s'ouvre en premier. Pour une question hors du
mémento, **Demander à Bafou** transmet la question à l'IA configurée, après
consentement.
