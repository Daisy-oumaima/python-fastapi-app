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
