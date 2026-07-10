# HANDOFF — finir la release PhotoCull v0.1.0

> Pour la prochaine session Claude. État au 2026-07-10 ~09:45. Tout le code est
> mergé sur `main` et pushé sur https://github.com/theodorebeaupre-prog/photocull
> (CI verte). Il reste : **GIF démo → README → release v0.1.0 → cask Homebrew → cleanup**.

## Contexte projet (30 secondes)

App macOS de culling photo IA, 100% locale (`~/Developer/PhotoCull`). Core Swift
package (41 tests verts) + app SwiftUI (XcodeGen, `project.yml`). Icône Icon
Composer intégrée (commit d1b4ca8). Compat Lightroom Classic (sidecars XMP) +
Lightroom cloud (Export Keepers). Historique complet : `.superpowers/sdd/progress.md`
(ledger git-ignoré, local). Le plan d'implémentation : `docs/superpowers/plans/2026-07-09-photocull-v0.1.md`.

Build local vérifié : `swift test --package-path Core` (41/41) et
`xcodegen generate && xcodebuild -project PhotoCull.xcodeproj -scheme PhotoCull -configuration Release -derivedDataPath build build`.
L'app buildée est dans `build/Build/Products/Release/PhotoCull.app`.

## 1. GIF démo — l'enregistrement est DÉJÀ FAIT

**Fichier : `~/Desktop/PhotoCull-demo-raw.mov`** (2200×1440, ~60 s, 2.6 MB).
Le film capture la fenêtre de l'app (région 120,80 1100×720) avec la démo
complète : welcome → panneau Ouvrir (dossier PhotoCull-Demo pré-sélectionné) →
grille qui se remplit avec badges blurry/suggested → Apply Suggestions (3 kept /
7 rejected) → Review avec K/X au clavier → Groups avec « Keep best, reject
rest » ×2 → retour Grid → Write XMP Sidecars → alerte « 10 XMP sidecar(s)
written. 4 photo(s) still undecided were skipped. » → OK.

**Défauts à couper au montage** : (a) ~2 s de welcome au début avant le premier
clic ; (b) un temps mort de ~5-10 s au milieu, panneau Ouvrir ouvert immobile
(entre l'ouverture du panneau et le clic sur Open — c'était un aller-retour
d'outil). Inspecte les timestamps avec des frames :
```sh
for t in 0 2 4 6 8 10 12 14 16 18 20; do ffmpeg -y -v error -ss $t -i ~/Desktop/PhotoCull-demo-raw.mov -frames:v 1 /tmp/f$t.png; done
```
Puis coupe le segment mort et concatène (ou garde juste du clic Open jusqu'à
l'alerte si c'est plus simple — c'est le cœur de la démo). Conversion GIF :
```sh
ffmpeg -i INPUT_TRIMMED.mov -vf "fps=10,scale=900:-1:flags=lanczos,split[a][b];[a]palettegen=max_colors=128[p];[b][p]paletteuse=dither=bayer" ~/Developer/PhotoCull/docs/demo.gif
```
Vise < 8 MB. Ensuite dans `README.md`, remplace la ligne
`<!-- TODO at release: demo GIF here -->` par `![PhotoCull demo](docs/demo.gif)`,
commit + push.

**Si le .mov est inutilisable et qu'il faut refaire une prise** — recette qui a
marché (après 2 échecs) :
- Photos de démo : régénérables avec le script scratchpad `gen-demo-photos.swift`
  (14 JPEG paysages avec EXIF, rafales + floues) → `~/Desktop/PhotoCull-Demo`.
  ⚠️ La prise a écrit 10 `.xmp` dans ce dossier — les supprimer avant retake.
- Reset état : `pkill -f PhotoCull/build` ; `rm -rf ~/Library/Application\ Support/PhotoCull/Sessions`.
- Le panneau Ouvrir démarre déjà sur PhotoCull-Demo (defaults
  `NSNavLastRootDirectory` déjà réglé).
- Relancer l'app, positionner la fenêtre à {120,80} taille {1100,720} via
  System Events (cibler le process par `unix id`, PAS par nom).
- Enregistrer : `screencapture -v -V 60 -R120,80,1100,720 out.mov` en arrière-plan.
- Piloter via computer-use (accès déjà accordé à `ca.isonord.photocull`).
  Pièges appris : cliquer d'abord la barre de titre pour ACTIVER la fenêtre
  (le 1er clic sur une fenêtre inactive ne presse pas les boutons) ; utiliser
  ⌘O plutôt que cliquer le bouton ; le panneau peut être lent — vérifier
  visuellement avant d'envoyer Return ; ne PAS utiliser ⌘⇧G (l'autocomplete a
  ouvert le mauvais dossier deux fois).

## 2. Release v0.1.0

1. **Workflow release** : copier/adapter `~/Developer/CLAUDE/MCPDeck/.github/workflows/release.yml`
   (pattern « signature optionnelle avec fallback unsigned » déjà éprouvé sur
   MCP Deck). Adapter : nom d'app PhotoCull, build via xcodegen + xcodebuild
   Release, zipper `PhotoCull.app` en `PhotoCull-vX.Y.Z.zip`, créer la GitHub
   Release sur push de tag `v*`.
2. Commit + push le workflow, puis :
   ```sh
   cd ~/Developer/PhotoCull && git tag v0.1.0 && git push origin v0.1.0
   gh run watch  # vérifier que la release passe et publie l'asset
   ```
3. Le repo n'a AUCUN secret configuré (comme MCP Deck au départ) → le workflow
   doit builder unsigned sans planter.

## 3. Cask Homebrew

Tap existant : `theodorebeaupre-prog/homebrew-tap` (contient déjà le cask
mcp-deck — s'en inspirer). Après la release :
```sh
curl -L https://github.com/theodorebeaupre-prog/photocull/releases/download/v0.1.0/PhotoCull-v0.1.0.zip | shasum -a 256
```
Créer `Casks/photocull.rb` dans le tap (version, sha256, url, `app "PhotoCull.app"`,
homepage, caveats « app non signée : xattr -cr » comme mcp-deck), push. Tester :
`brew install --cask theodorebeaupre-prog/tap/photocull`. Le README de PhotoCull
référence déjà cette commande.

## 4. Cleanup après release

- `rm -rf ~/Desktop/PhotoCull-Demo ~/Desktop/PhotoCull-demo-raw.mov` (après le GIF)
- `rm -rf ~/Library/Application\ Support/PhotoCull/Sessions`
- `defaults delete ca.isonord.photocull NSNavLastRootDirectory NSNavLastCurrentDirectory 2>/dev/null`
- Supprimer ce `HANDOFF.md` du repo une fois tout terminé.

## 5. Après la release (backlog connu, pas urgent)

- **Smoke test humain** : vérifier que Lightroom Classic lit les sidecars sur de
  vrais RAW (et le comportement Lightroom cloud) — critère du spec jamais validé.
- Badges CI + section « Why local matters » dans le README (prévus au spec).
- v0.2 (voir ledger) : reconnaître ses propres sidecars pour permettre le
  re-export ; RAW+JPEG pairing ; déplacer le sidecar avec la photo dans
  `_rejects` ; cache de vignettes ; seuils d'analyse centralisés dans `Scoring`.
- Idée en attente de Théo : alternative open source à CleanShot X.
