# TP 6 – Réponses aux questions

## Q1. Pourquoi la variable n'est-elle pas disponible dans la step qui l'a définie, mais seulement dans les suivantes ?
`echo "APP_NAME=my-app" >> $GITHUB_ENV` ne modifie pas l'environnement du shell en cours : il ajoute seulement une ligne à un fichier. Le shell de la step a déjà été lancé avec son environnement figé. C'est le runner qui, une fois la step terminée, lit ce fichier et injecte les variables dans les steps suivantes.

## Q2. Que constate-t-on dans `verify-env` ? Quelle est la portée de GITHUB_ENV ?
La step affiche `APP_NAME = ` : la variable est vide. Chaque job s'exécute sur un runner distinct et neuf, et le fichier `GITHUB_ENV` est propre à un job. La portée de `GITHUB_ENV` est donc limitée aux steps suivantes du même job.

## Q3. Que se passe-t-il avec `>` au lieu de `>>` dans GITHUB_OUTPUT, avec deux outputs dans la même step ?
`>` écrase le fichier : le second `echo` efface le premier. Seul le dernier output est conservé, et le premier est vide à la lecture. Il faut utiliser `>>` pour ajouter plusieurs outputs.

## Q4. Pourquoi GITHUB_ENV ne suffit-il pas entre jobs, alors que GITHUB_OUTPUT fonctionne ?
`GITHUB_ENV` est limité à un job, car chaque job a son propre runner. `GITHUB_OUTPUT`, déclaré dans `outputs:` du job, est transmis par GitHub aux jobs dépendants, qui le lisent via `needs.<job>.outputs.<nom>`.

## Q5. Que se passe-t-il si on retire `needs: build` du job deploy ?
`deploy` n'attend plus `build` et démarre en parallèle. Le contexte `needs.build` n'est plus disponible : `${{ needs.build.outputs.full_version }}` est vide. On perd l'ordre d'exécution et le transfert de la valeur. `deploy` peut même s'exécuter si `build` échoue.# Réponses

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
Mesures : docker-hello = 11 s, build (composite) = 9 s


---

# Réponses TP 8 – Stratégies GitHub Actions

## Q1. Combien de jobs sont générés ? Liste des combinaisons.

La matrice génère **6 jobs** (2 systèmes × 3 versions de Python) :

- ubuntu-latest + Python 3.11
- ubuntu-latest + Python 3.12
- ubuntu-latest + Python 3.13
- windows-latest + Python 3.11
- windows-latest + Python 3.12
- windows-latest + Python 3.13

## Q2. Combien de jobs au total après exclude et include ?

Il y a **6 jobs** au total :

- Matrice de base : 6 combinaisons
- `exclude` de windows-latest + 3.11 : 6 − 1 = 5 combinaisons
- `include` de ubuntu-latest + 3.14 (experimental) : 5 + 1 = **6 jobs**

Liste finale : ubuntu 3.11, 3.12, 3.13, 3.14 (expérimental) et windows 3.12, 3.13.

## Q3. Que se passerait-il si on excluait la combinaison 3.14 ? Pourquoi ?

**Rien ne se passerait** : le job ubuntu-latest + 3.14 serait quand même créé.

`exclude` s'applique uniquement aux combinaisons générées par la matrice
d'origine, **avant** `include`. La version 3.14 n'existe que dans `include`,
donc l'exclusion ne correspond à aucune combinaison et est ignorée
(sans erreur). Pour supprimer ce job, il faut retirer l'entrée `include`.

## Q4. Quelle différence observée entre fail-fast true et false ?

Avec un test qui échoue uniquement sur Windows (`test_break.py`) :

| | Réussis | Échoués | Annulés |
|---|---|---|---|
| `fail-fast: true` | 4 | 1 | 1 |
| `fail-fast: false` | 4 | 2 | 0 |

- Avec **`fail-fast: true`** (valeur par défaut), dès qu'un job échoue
  (windows 3.12), GitHub **annule** les jobs encore en cours
  (windows 3.13). On est prévenu vite et on économise des minutes de calcul,
  mais on ne voit pas tous les résultats.
- Avec **`fail-fast: false`**, tous les jobs vont **jusqu'au bout**
  (windows 3.12 et 3.13 échouent tous les deux) : on obtient un bilan complet.

**Quand choisir `true` ?** Quand tout doit passer pour valider le code
(par exemple une pull request classique) : un seul échec suffit à bloquer,
donc inutile de consommer des ressources pour le reste.

**Quand choisir `false` ?** Pour diagnostiquer la compatibilité sur toutes
les combinaisons (par exemple savoir si le bug touche un seul OS ou toutes les
versions de Python), ou quand la matrice contient des jobs expérimentaux.

## Q5. Deux raisons d'utiliser max-parallel en entreprise

1. **Maîtriser les coûts et les quotas de runners.** Le nombre de jobs
   simultanés est limité (plan GitHub, runners self-hosted en nombre fini).
   Limiter la matrice évite qu'un seul workflow monopolise les runners et
   bloque les pipelines des autres équipes.
2. **Protéger les ressources partagées.** Si les tests utilisent une base de
   données de test, un environnement de staging ou une API externe avec limite
   de requêtes (rate limit), trop de jobs en parallèle provoquent des
   conflits ou des échecs aléatoires.
