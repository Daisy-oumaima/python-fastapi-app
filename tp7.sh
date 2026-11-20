#!/usr/bin/env bash
# TP7 - à lancer à la racine de votre dépôt Git (celui des TP précédents)
set -e
git checkout -b feature/tp-actions
mkdir -p .github/workflows .github/actions/build-info .github/actions/docker-hello

# ---------- Partie 0 + 1 + 3 : workflow ----------
cat > .github/workflows/tp-actions.yml <<'YML'
name: Third-Party and Custom Actions Lab
on:
  workflow_dispatch:
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Run build info action
        id: info
        uses: ./.github/actions/build-info
        with:
          app-name: my-app

      - name: Print build id
        run: echo "Build id is ${{ steps.info.outputs.build-id }}"

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: 20

      - name: Print Node.js version
        run: node --version

      - name: Generate build report
        run: echo "Node $(node --version) - $(date)" > report.txt

      - name: Upload build report
        uses: actions/upload-artifact@v4
        with:
          name: build-report
          path: report.txt

  verify:
    runs-on: ubuntu-latest
    needs: build
    steps:
      - name: Download build report
        uses: actions/download-artifact@v4
        with:
          name: build-report

      - name: Print build report
        run: cat report.txt

  docker-hello:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Run docker hello action
        uses: ./.github/actions/docker-hello
        with:
          who: World
YML

# ---------- Partie 3 : action composite ----------
cat > .github/actions/build-info/action.yml <<'YML'
name: Build Info
description: Print build details and return a build id
inputs:
  app-name:
    description: Application name
    required: true
  version:
    description: Application version
    default: "1.0.0"
outputs:
  build-id:
    description: Generated build identifier
    value: ${{ steps.make-id.outputs.build-id }}
runs:
  using: composite
  steps:
    - name: Print build details
      shell: bash
      run: echo "Building ${{ inputs.app-name }} v${{ inputs.version }}"
    - name: Generate build id
      id: make-id
      shell: bash
      run: echo "build-id=${{ inputs.app-name }}-${{ inputs.version }}" >> "$GITHUB_OUTPUT"
YML

# ---------- Partie 4 : action Docker ----------
cat > .github/actions/docker-hello/Dockerfile <<'EOF2'
FROM alpine:3.20
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
EOF2

cat > .github/actions/docker-hello/entrypoint.sh <<'EOF2'
#!/bin/sh
echo "Hello, $1"
EOF2
chmod +x .github/actions/docker-hello/entrypoint.sh

cat > .github/actions/docker-hello/action.yml <<'YML'
name: Docker Hello
description: Say hello from a Docker container
inputs:
  who:
    description: Who to greet
    required: true
    default: World
runs:
  using: docker
  image: Dockerfile
  args:
    - ${{ inputs.who }}
YML

# ---------- Réponses ----------
cat > SECURITY-NOTES.md <<'MD'
# Security notes

**Q3. Pourquoi épingler une version (@v4) plutôt que @main ?**
`@main` pointe vers la dernière version de la branche : le code peut changer à tout moment sans que je le sache.
Un bug, un changement cassant ou un compromis du dépôt (supply chain attack) serait exécuté directement dans mon pipeline,
avec accès à mes secrets. `@v4` est un tag stable : le comportement est reproductible et prévisible
(le plus sûr étant d'épingler le SHA complet du commit).

**Q4. Le badge « créateur vérifié » garantit-il qu'une action est sûre ?**
Non. Il prouve seulement que l'identité de l'éditeur (organisation) est vérifiée par GitHub, pas que le code est sans faille
ni sans malveillance. Un compte vérifié peut être compromis, ou publier une version buggée ou vulnérable.
Il faut toujours relire le code et épingler une version.

**Q5. Deux vérifications avant d'utiliser une action d'un fournisseur inconnu en production :**
1. Lire le code source (action.yml, scripts, Dockerfile) pour s'assurer qu'il n'envoie pas de secrets/données vers l'extérieur ni n'exécute de code suspect.
2. Vérifier la réputation et la maintenance : nombre d'étoiles, activité récente, issues/PR, licence, nombre d'utilisateurs ;
   puis épingler un SHA de commit précis et limiter les `permissions` du GITHUB_TOKEN.
MD

cat >> REPONSES.md <<'MD'
# Réponses

**Q1. Pourquoi actions/checkout n'a-t-il pas besoin de `with` alors que setup-node en a besoin ?**
Toutes les entrées de `checkout` ont des valeurs par défaut adaptées (dépôt courant, ref du workflow, etc.), donc aucun paramètre n'est obligatoire.
`setup-node` doit savoir quelle version de Node installer (`node-version`) : sans ce paramètre, il ne sait pas quoi installer / utilise une valeur non voulue.
`with` sert à passer des inputs, qui ne sont nécessaires que lorsque le défaut ne convient pas.

**Q2. Pourquoi `verify` ne retrouve-t-il pas report.txt sans l'artefact alors que les deux jobs partagent le même dépôt ?**
Chaque job s'exécute sur un runner distinct, propre et vierge. Le dépôt n'est que le code versionné ; `report.txt` est généré
pendant l'exécution et n'est pas commité, il n'existe donc que sur le runner du job `build`, détruit à la fin du job.
Les artefacts sont le mécanisme pour transférer des fichiers d'un job à l'autre.

**Q6. Pourquoi checkout doit-il s'exécuter avant l'appel d'une action locale ?**
Une action locale (`./.github/actions/...`) est un dossier du dépôt. Le runner démarre vide : tant que `checkout` n'a pas
cloné le dépôt, `action.yml` n'existe pas sur le runner et l'action est introuvable.

**Q7. Pourquoi `shell: bash` est-il obligatoire sur les steps `run` d'une action composite ?**
Contrairement à un workflow, une action composite ne sait pas dans quel contexte elle sera appelée (Linux, Windows, macOS), donc
GitHub n'a pas de shell par défaut. Il faut le préciser explicitement pour que le comportement soit déterministe.

**Partie 4 – comparaison :** l'action Docker est plus lente car il faut construire l'image (alpine + Dockerfile) à chaque exécution,
alors que l'action composite exécute simplement des steps shell sur le runner (quelques secondes).
MD

git add .
git commit -m "Add TP7 workflow, composite action, docker action and answers"
git push -u origin feature/tp-actions
