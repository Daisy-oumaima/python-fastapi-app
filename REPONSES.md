# TP 7– Réponses aux questions

Q1. Pourquoi actions/checkout n’a-t-il pas besoin de with alors que setup-node en a besoin ?
Toutes les entrées de checkout ont des valeurs par défaut adaptées (dépôt courant, branche du workflow), donc aucun paramètre n’est obligatoire. setup-node doit savoir quelle version de Node installer (node-version). with sert à passer des paramètres quand la valeur par défaut ne suffit pas.

Q2. Pourquoi verify ne retrouve-t-il pas report.txt sans l’artefact ?
Chaque job tourne sur un runner distinct et vierge. Le dépôt ne contient que les fichiers commités. report.txt est généré pendant l’exécution du job build et n’existe que sur ce runner, qui est détruit à la fin du job. Les artefacts servent à transférer des fichiers d’un job à l’autre.

Q3. Pourquoi épingler une version (@v4) plutôt que @main ?
@main pointe vers le dernier code de la branche, qui peut changer à tout moment. Un bug, un changement cassant ou un compromis du dépôt serait exécuté dans votre pipeline, avec accès à vos secrets. @v4 est stable et reproductible. Le plus sûr est d’épingler le SHA complet du commit.

Q4. Le badge « créateur vérifié » garantit-il qu’une action est sûre ?
Non. Il prouve seulement que l’identité de l’éditeur est vérifiée par GitHub, pas que le code est sans faille ni sans malveillance. Un compte vérifié peut être compromis ou publier une version vulnérable. Il faut toujours relire le code et épingler une version.

Q5. Deux vérifications avant d’utiliser une action inconnue en production :

Lire le code source (action.yml, scripts, Dockerfile) pour s’assurer qu’il n’envoie pas de secrets ou de données vers l’extérieur.
Vérifier la réputation et la maintenance (étoiles, activité récente, issues, licence), puis épingler un SHA précis et limiter les permissions du GITHUB_TOKEN.

Q6. Pourquoi checkout doit-il s’exécuter avant l’appel d’une action locale ?
Une action locale est un dossier du dépôt (./.github/actions/...). Le runner démarre vide : tant que checkout n’a pas cloné le dépôt, le fichier action.yml n’existe pas et l’action est introuvable.

Q7. Pourquoi shell: bash est obligatoire dans une action composite ?
Une action composite ne sait pas dans quel environnement elle sera appelée (Linux, Windows ou macOS). GitHub n’a donc pas de shell par défaut pour elle, et il faut le préciser explicitement.

Partie 4 : comparaison des temps.
L’action Docker est plus lente car l’image doit être construite à chaque exécution. L’action composite exécute directement des commandes shell sur le runner. Dans votre run : docker-hello = 11 s, build = 9 s.
