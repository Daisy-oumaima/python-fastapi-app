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
