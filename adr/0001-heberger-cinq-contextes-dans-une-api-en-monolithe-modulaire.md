# ADR 0001 · Héberger cinq bounded contexts dans une seule API centrale en monolithe modulaire plutôt qu'en services séparés

- Statut : proposé · Date : 2026-10-27 · Auteurs : Abdoul DALMEIDA, El Housseine SY · Spécialité : Dev
- Élément du C4 : conteneur « API centrale » (N2) et ses cinq modules (N3)

## Contexte

- Le TP 5 a fait émerger 8 bounded contexts. Cinq d'entre eux (Référentiel ruchers, Santé des colonies, Terrain, Production, Identité et accès) ont un rythme de charge, un langage et un lieu d'exécution identiques : une API qui répond aux requêtes de l'App terrain et du tableau de bord.
- Contraintes du CDC : équipe de deux personnes, projet de quatre mois (section XI), temps de réponse de l'API < 500 ms (p95) (section 8.1), 300 utilisateurs et 400 ruches (section 1.4), pipeline CI/CD et conteneurs à fournir pour chaque service (section 9.1).
- Point chaud d'origine : le piège du « un conteneur par contexte » signalé par le TP 6 : 5 services, 5 bases, 5 pipelines, 5 supervisions.

## Options

1. **Monolithe en couches, sans frontières de contexte (le plus simple)** : un seul code organisé par couche technique (contrôleurs, services, dépôts).
   + Démarrage le plus rapide.
   − Les règles métier se mélangent ; extraire un contexte plus tard devient très coûteux ; les glossaires du TP 5 ne se retrouvent plus dans le code.
2. **Monolithe modulaire** : un seul déploiement, mais un module par contexte, un schéma de base par module et des échanges par événements.
   + Un seul pipeline, un seul conteneur à superviser et à sécuriser.
   + Les frontières du TP 5 restent visibles dans le code ; un module peut être extrait en service plus tard.
   − Un seul déploiement pour cinq contextes : un défaut bloque l'ensemble.
   − Les frontières ne sont tenues que par la discipline de l'équipe, sauf outillage.
3. **Un service et une base par contexte** : cinq conteneurs d'API.
   + Déploiement et mise à l'échelle indépendants.
   − Cinq pipelines, cinq supervisions, cinq surfaces d'attaque pour une équipe de deux et une charge de quelques dizaines de requêtes par minute ; cohérence distribuée dès la première semaine.

## Décision

**Option 2**, parce que les cinq contextes partagent le même profil d'exécution, que le coût de l'option 3 (déploiement, supervision, sécurité) n'est justifié par aucune différence de charge, de langage ou de lieu, et que l'option 1 perd le travail du TP 5. Les trois contextes qui ont une vraie raison technique d'être à part (Collecte, Prévision, Impact et rapports) restent hors de l'API (voir `docs/c4/conteneurs.md`).

Règles associées : un schéma et un rôle SQL par module ; aucune importation directe d'un module dans un autre, seulement des événements (voir ADR 0002) ; une règle de dépendances vérifiée dans la CI (par exemple `dependency-cruiser`).

## Conséquences

+ Un conteneur, un pipeline, un point de supervision pour cinq contextes.
+ Extraction possible d'un module en service si le besoin apparaît.
− Un déploiement défectueux touche les cinq contextes.
− Sans la règle de dépendances en CI, les frontières s'érodent.

À surveiller : nombre de violations de dépendances détectées en CI (cible 0) ; durée du build.

## Révision

Rouvrir si un module a besoin d'un rythme de déploiement ou d'une charge différents des autres (par exemple un module bloque plus de deux déploiements par semaine des autres), ou si le p95 de l'API dépasse 500 ms à cause d'un seul module.