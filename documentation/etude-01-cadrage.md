# Flux — Étude de cadrage (phase 1)

Analyse point par point des idées de départ, puis plan de démarrage.
Objectif transversal : **réutiliser les primitives natives de Claude Code et de GitHub**
(hooks, skills, subagents, branch protection, Actions) plutôt que construire un
orchestrateur maison. Flux est une *couche de convention et de configuration*, pas
un nouveau moteur.

---

## 1. Hooks pour les étapes sensibles (tests, lint…)

**Ce que Claude Code offre nativement.** Les hooks (`.claude/settings.json`) se
déclenchent sur des événements précis : `PostToolUse` (après un Edit/Write),
`PreToolUse` (avant un Bash, avec matcher sur la commande), `Stop` (quand l'agent
veut terminer son tour). Un hook qui sort avec le code 2 **bloque** l'action et
renvoie son message à l'agent, qui corrige tout seul. C'est exactement le
mécanisme recherché : la boucle "l'agent ne peut pas avancer tant que ce n'est
pas vert" est native.

**Points de vigilance.**
- Lancer toute la suite de tests après chaque édition est trop lent et coûteux.
  Bonne répartition : lint/format **du fichier modifié** en `PostToolUse`
  (rapide), suite de tests en `PreToolUse` sur `git commit`/`git push` et/ou en
  `Stop`.
- Les hooks sont **locaux et contournables** (l'agent ou l'humain peut les
  désactiver). Ils sont la première ligne de défense, pas la garantie — voir §2.
- Les commandes (lint, test) varient par projet → elles doivent venir de
  `flux-config.yml` (§7), le script de hook les lit.

**Décision proposée.** Un seul script de hook générique (`flux-gate.sh` ou
équivalent) piloté par la config, plutôt qu'un hook par outil.

---

## 2. Mise en production bloquée par les étapes sensibles

**Le blocage réel ne peut pas reposer sur les hooks** (locaux). La source de
vérité doit être côté GitHub :

- **GitHub Actions** : workflow CI qui rejoue lint + tests + build.
- **Branch protection sur `main`** : required status checks (la CI doit être
  verte) + interdiction du push direct.
- **GitHub Environments** : un environnement `production` avec *required
  reviewers* = le déploiement attend une validation humaine explicite, même si
  tout est vert.

**Architecture en deux lignes de défense.**
1. Hooks locaux : feedback immédiat à l'agent, corrige avant même de pousser.
2. CI + branch protection : garantie infranchissable, y compris si les hooks
   sont contournés.

Rien à inventer ici : c'est de la configuration GitHub standard, que Flux peut
fournir sous forme de templates de workflows.

---

## 3. Skills

État des lieux : le socle existe déjà en grande partie.

| Besoin exprimé | Existant | Manque |
|---|---|---|
| SEO / GEO / accessibilité | skills `seo` + `accessibility` | volet GEO (Generative Engine Optimization) à ajouter au skill `seo` |
| Frontend UI/UX | skill `frontend-design` | rien de bloquant |
| Définition des specs | skill `spec-interview` | gestion multi-specs (voir ci-dessous) |
| Billets GitHub | — (`gh-address-comments`, `gh-fix-ci` couvrent l'aval) | skill `gh-issue` (création/rédaction) |
| Rédaction des PR | — | skill `gh-pr` |

**Refonte du skill specs (le vrai chantier).**
- Sortie en `specs/SPEC-<ref>.md` au lieu d'un `SPEC.md` unique écrasé.
- `<ref>` = slug ou numéro d'issue GitHub (lien naturel avec §gh-issue).
- Frontmatter minimal : statut (draft / validé / implémenté), issue liée, date.
- Un index `specs/README.md` généré/maintenu par le skill.

**Skills `gh-issue` et `gh-pr`.** Fines : un template + les conventions du
projet (labels, format de titre, lien vers la spec). Elles complètent la chaîne
existante : `gh-issue` → `gh-pr` → `gh-fix-ci` → `gh-address-comments` = cycle
de vie complet d'une contribution.

**Anti-éparpillement.** Ne pas réécrire les skills existants ; les trois
chantiers sont : refonte specs, `gh-issue`, `gh-pr`. Le volet GEO et l'UI/UX
sont des améliorations de confort, pas des fondations.

---

## 4. Review automatique + blocage du merge jusqu'à validation humaine

Deux mécanismes indépendants, tous deux natifs GitHub :

- **Review auto** : `claude-code-action` (GitHub Action officielle) sur
  `pull_request` → l'agent poste une review en commentaires. Alternative
  ponctuelle : `/code-review ultra <PR#>` depuis Claude Code. L'agent **ne
  donne jamais l'approbation** — il commente.
- **Blocage du merge** : branch protection = *require 1 approving review*
  (humaine, puisque l'agent n'approuve pas) + *required status checks*.
  `CODEOWNERS` si on veut cibler qui doit valider.

Résultat : le merge est physiquement impossible sans un humain, quelle que soit
la qualité de la review automatique. Aucun code à écrire, uniquement de la
configuration + un workflow.

---

## 5. Multi-agent

**Ce qui existe** : les subagents (`.claude/agents/*.md`) — déjà un
`security-reviewer` dans le projet. Un subagent = un rôle avec ses instructions,
ses outils autorisés, éventuellement son modèle.

**Recommandation : commencer petit.** L'expérience générale des systèmes
multi-agents : la valeur vient de 2-3 rôles bien définis, pas d'un essaim.
Rôles candidats pour Flux v1 :
- `reviewer` (qualité/architecture — complète `security-reviewer`) ;
- `qa` (exécute l'app, vérifie le comportement réel, pas juste les tests).

L'orchestration reste la session principale de Claude Code. Les patterns plus
ambitieux (agents planificateur/implémenteur parallèles, agents cloud planifiés)
sont **explicitement hors scope v1** — c'est le premier piège d'éparpillement.

---

## 6. `flux-config.yml`

**Fait important** : Claude Code ne lit pas nativement un fichier de config
arbitraire. `flux-config.yml` est une convention de *notre* couche : ce sont les
scripts de hooks et les skills Flux qui le lisent.

Schéma v1 volontairement minimal :

```yaml
# flux-config.yml
project:
  name: mon-projet
commands:            # lues par les hooks (§1)
  lint: "vendor/bin/pint --test"
  test: "php artisan test"
  build: "npm run build"
gates:               # quelles étapes bloquent quoi
  on_edit: [lint]
  on_push: [lint, test]
specs:
  dir: specs/        # utilisé par le skill specs (§3)
github:
  labels: [flux]     # utilisé par gh-issue / gh-pr
```

On n'ajoute une clé que lorsqu'un consommateur (hook ou skill) en a besoin.
Prévoir `yq` (ou un petit parseur) comme dépendance des scripts de hooks.

---

## 7. Packaging (question transversale non listée mais structurante)

Deux options pour distribuer Flux sur plusieurs projets :

1. **Répertoire `.claude/` template** copié dans chaque projet — simple, mais
   les mises à jour se propagent mal.
2. **Plugin Claude Code** (skills + hooks + agents + commands empaquetés,
   installable depuis un marketplace git) — le bon vecteur à terme.

**Décision proposée** : développer d'abord *dans ce dépôt* comme un `.claude/`
ordinaire (itération rapide), et convertir en plugin en fin de v1, quand les
interfaces (config, noms de skills) sont stables.

---

## Décisions de stack (tranchées le 2026-08-06)

- **Forge : GitHub** pour la v1. Toute la chaîne s'appuie sur `gh` CLI,
  `claude-code-action`, branch protection et Environments. On pose quand même
  `forge: github` dans `flux-config.yml` dès le départ : les skills passent par
  cette indirection, ce qui garde un portage Gitea/Forgejo possible en v2 sans
  réécriture.
- **Pilote : Laravel / Vue / Inertia.** Monolithe = un seul dépôt, une seule
  config de gates : `pint` (lint), `larastan` (statique), `pest` (tests),
  `vite build` (build). Inertia évite une API séparée à gérer. Bonus : la stack
  est celle de l'apprentissage en cours (projet réel).
- **Second pilote (phase 4)** : Next.js, pour prouver la généricité de
  `flux-config.yml` sur une toolchain différente.

## Plan de démarrage (sans s'éparpiller)

Un principe : **chaque phase se termine par une démonstration sur un projet
pilote réel** (le mini-ATS Laravel est un bon candidat). Pas de phase suivante
tant que la démo ne passe pas.

### Phase 0 — Socle (courte)
- Figer le schéma v1 de `flux-config.yml` (§6).
- Choisir le projet pilote et y poser une config.
- **Démo : `yq` lit la config depuis un script.**

### Phase 1 — Garde-fous (le cœur de la valeur)
- Script de hook générique piloté par la config : lint en `PostToolUse`,
  tests en `PreToolUse` sur `git push`.
- Workflow CI template + branch protection sur le pilote.
- **Démo : l'agent introduit une erreur de lint → bloqué → corrige seul ;
  un push avec tests rouges est refusé localement ET par la CI.**

### Phase 2 — Cycle spec → issue → PR
- Refonte du skill specs (`SPEC-<ref>.md` + index).
- Skills `gh-issue` et `gh-pr`.
- **Démo : une feature part d'une interview de spec et aboutit à une PR
  correctement rédigée et liée à son issue.**

### Phase 3 — Review et gate humain
- Workflow `claude-code-action` de review sur PR.
- Branch protection : approbation humaine requise + environnement
  `production` avec required reviewer.
- **Démo : une PR reçoit une review agent ; le merge est impossible sans
  approbation humaine ; le déploiement attend la validation.**

### Phase 4 — Extension (seulement si 1-3 tiennent)
- Subagents `reviewer` / `qa` (§5).
- Volet GEO du skill `seo`, améliorations UI/UX.
- Conversion en plugin Claude Code (§7).

### Hors scope v1 (liste d'éparpillement assumée)
- Orchestrateur multi-agent parallèle, agents cloud planifiés.
- Dashboard / UI de suivi.
- Support d'autres forges que GitHub.
- Généralisation multi-langages de la config au-delà des besoins du pilote.
