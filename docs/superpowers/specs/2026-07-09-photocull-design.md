# PhotoCull — Design v0.1

**Date :** 2026-07-09
**Statut :** approuvé (design présenté et validé en session de brainstorming)
**Nom de travail :** PhotoCull — le nom final sera décidé à la création du repo GitHub.

## Pitch

> AI photo culling for macOS — free, open source, 100% on-device. Stop paying $20/month.

Les photographes paient 10–30 $/mois pour Aftershoot ou Narrative Select afin de trier des milliers de photos après un shoot (floues, yeux fermés, doublons de rafale). Il n'existe aucune alternative open source sérieuse. PhotoCull offre le même workflow, gratuit et privé, parce que toute l'analyse roule sur le Mac de l'utilisateur via les frameworks Apple (Vision/CoreML). Coût de build et de run : 0 $.

**Objectifs du projet :** visibilité GitHub (stars) + portfolio. Avantage différenciant : l'auteur est photographe professionnel (crédibilité de niche).

## Scope v0.1

### Inclus

1. **Import** : l'utilisateur ouvre un dossier de photos. Formats supportés : tout ce que macOS décode nativement (JPEG, HEIC, PNG, TIFF, et les RAW couverts par Image I/O / Core Image RAW). Pas de récursion dans les sous-dossiers en v0.1 (un dossier = une session de culling).
2. **Analyse 100 % locale** — aucune requête réseau, jamais :
   - **Netteté** : score de flou par photo. Métrique : variance du laplacien, calculée sur une version réduite de l'image (convolution via vImage/Core Image — Vision n'offre pas de requête de netteté directe).
   - **Yeux fermés** : détection via les landmarks de visage de Vision (`VNDetectFaceLandmarksRequest`). S'applique seulement aux photos où des visages sont détectés.
   - **Regroupement rafales/quasi-doublons** : clustering par distance d'empreinte visuelle (`VNGenerateImageFeaturePrintRequest`) combinée à une fenêtre temporelle basée sur l'horodatage EXIF.
   - **Score global** par photo, agrégé des signaux ci-dessus, et suggestion de la « meilleure de la rafale » dans chaque groupe.
3. **UI de review** :
   - **GridView** : grille de vignettes avec badges (flou / yeux fermés / membre d'un groupe), tri par score.
   - **ReviewView** : mode photo par photo, navigation 100 % clavier — `K` = keep, `X` = reject, flèches = naviguer.
   - **GroupView** : vue par groupe de rafale, meilleure photo suggérée mise en évidence, sélection rapide du keeper.
4. **Sortie non-destructive** — deux modes au choix de l'utilisateur :
   - Déplacer les photos rejetées dans un sous-dossier `_rejects` (déplacement, jamais de suppression).
   - Écrire des **sidecars XMP** avec flags/ratings (pick/reject, étoiles) lisibles directement par Lightroom Classic. C'est la feature clé pour l'audience photographe : culler ici, éditer dans Lightroom.
5. **Vie privée** : zéro télémétrie, zéro compte, zéro cloud. C'est un argument produit, pas juste une absence de feature.

### Exclu (v0.2+)

- Accès à la photothèque Photos.app (permissions capricieuses, pas nécessaire pour le workflow photographe pro qui travaille en dossiers).
- Plugin Lightroom direct (les sidecars XMP couvrent le besoin en v0.1).
- Scoring esthétique ML avancé (sourires, composition, exposition).
- Traitement batch de plusieurs dossiers.
- Localisation — interface en anglais seulement en v0.1 (audience GitHub).

## Architecture

App SwiftUI, cible macOS 14+. Trois unités à responsabilité unique :

### 1. `CullEngine` (analyse)

- Pipeline async qui traite les images du dossier avec une **limite de concurrence** (TaskGroup borné) pour ne pas saturer mémoire/CPU sur un dossier de 3000 RAW.
- Chaque image passe les requêtes Vision nécessaires (netteté, visages/landmarks, feature print) en une seule ouverture de l'image.
- Produit un `PhotoAnalysis` par image : scores, empreinte, métadonnées EXIF utiles (date de prise de vue).
- **Interface** : entrée = URL de dossier ; sortie = flux (`AsyncSequence`) de `PhotoAnalysis` pour que l'UI se remplisse progressivement.

### 2. `Grouping` (clustering)

- Entrée : la liste des `PhotoAnalysis` ; sortie : des `PhotoGroup` (groupes de rafale/quasi-doublons) avec un keeper suggéré par groupe.
- Algorithme : tri chronologique, fenêtre temporelle glissante sur l'horodatage EXIF, puis distance d'empreinte visuelle pour confirmer l'appartenance au groupe.
- Pur et testable : aucune dépendance UI ni disque.

### 3. UI (SwiftUI)

- `GridView`, `ReviewView`, `GroupView` comme décrit dans le scope.
- Un store observable (`CullSession`) tient l'état : analyses, groupes, décisions keep/reject. Persisté en JSON dans Application Support pour pouvoir reprendre une session. **Les fichiers originaux ne sont jamais modifiés** ; les seules écritures sont le déplacement vers `_rejects` et les sidecars XMP, aux emplacements choisis par l'utilisateur.

### Gestion d'erreurs

- Fichier illisible/corrompu → badge « non analysé » dans l'UI, la photo reste visible et cullable manuellement. Le pipeline ne crash jamais pour une image.
- Pas de visage détecté → le signal « yeux fermés » est simplement absent (pas un défaut).
- Écriture refusée (dossier en lecture seule) → erreur claire à l'utilisateur au moment de l'export, la session reste intacte.

### Tests

- XCTest sur `CullEngine` (scoring) et `Grouping` (clustering) avec des **fixtures générées par script** : images nettes vs floutées programmatiquement, séries horodatées pour les groupes.
- Tests du writer XMP : le sidecar généré contient les balises attendues (comparaison à un golden file).
- L'UI n'est pas testée unitairement en v0.1 ; la logique décisionnelle vit dans le store, qui lui est testable.

## Distribution

Même playbook que MCP Deck :

- Repo GitHub public, licence MIT, copyright ISO NORD CA.
- CI GitHub Actions : build + tests sur chaque push, release workflow avec signature optionnelle (réutiliser celui de MCP Deck).
- Cask dans le Homebrew tap existant (`homebrew-tap`).
- README orienté conversion : GIF démo du workflow de culling en tête, tableau comparatif vs Aftershoot/Narrative Select (prix, cloud vs local, open source), badges, section « Why local matters » (vie privée + coût).

## Principes UX (v0.1)

Trois principes de psychologie UX sont intégrés au design de l'interface :

- **Smart defaults** : l'analyse produit des décisions *suggérées* (flou ou yeux fermés → reject suggéré, keeper de rafale → keep suggéré, autres membres de la rafale → reject suggéré). Un bouton « Apply Suggestions » remplit d'un coup les photos encore indécises ; l'utilisateur ajuste au lieu de décider de zéro. Les suggestions n'écrasent jamais une décision manuelle.
- **Goal gradient** : barre de statut permanente dont la progression compte l'analyse comme première étape complétée (jamais 0 % une fois les photos chargées), avec décompte « kept · rejected · to go » pour créer du momentum.
- **Aversion à la perte / transparence** : les confirmations et messages d'export nomment des quantités concrètes (« Move 41 rejected photos? », « 12 photos still undecided were skipped »).

La réciprocité (résultats complets sans compte ni upload) et l'effet de contraste (tableau comparatif 0 $ vs 10-30 $/mois) s'appliquent au README plutôt qu'à l'UI. L'effet IKEA n'est pas applicable (pas d'inscription en v0.1).

## Critères de succès v0.1

- Culler un dossier réel de 500+ photos (RAW inclus) sans crash ni fuite mémoire, avec des groupes de rafale sensés.
- Les sidecars XMP sont reconnus par Lightroom Classic (flags et ratings visibles).
- Installation en une commande via Homebrew.
- README avec GIF démo publié au moment de la release.
