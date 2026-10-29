# ADR 0002 · Découpler les contextes par des événements versionnés sur le broker MQTT plutôt que par des appels REST synchrones

- Statut : proposé · Date : 2026-10-27 · Auteurs : Abdoul DALMEIDA, El Housseine SY · Spécialité : Dev
- Élément du C4 : flèches « API centrale → Broker MQTT », « Service d'ingestion → Broker MQTT » et « Plateforme de données → Broker MQTT » (N2), et composant « Bus d'événements » (N3)

## Contexte

- La context map du TP 5 relie les contextes par des événements `.v1` : `MesureValidée.v1` a trois consommateurs (Santé, Prévision, Impact), `RisqueDétecté.v1` va de Prévision à Santé, `AlerteLevée.v1` de Santé à Terrain.
- Contraintes du CDC : sites à connectivité intermittente et flux asynchrone capteur → dashboard (section 6.2), synchronisation différée par files de messages (section 5.2), broker MQTT central déjà fourni (annexe D), aucune perte de donnée après une coupure (UC-CY01).
- Point chaud d'origine : l'arrêt d'un contexte ne doit pas empêcher les autres de travailler (Santé doit lever une alerte même si Terrain est en cours de redéploiement).

## Options

1. **Appels REST synchrones entre contextes (le plus simple)** : chaque contexte appelle l'API de l'autre.
   + Simple à comprendre et à déboguer ; réponse immédiate.
   − Couplage dans le temps : si le consommateur est arrêté, l'appelant échoue ; trois appels pour une seule mesure validée.
2. **Événements versionnés sur le broker MQTT** : le producteur publie `X.v1`, chaque consommateur s'abonne.
   + Un producteur, plusieurs consommateurs sans les connaître.
   + Les messages sont retenus pendant une panne et rattrapés ensuite.
   − Cohérence à terme, ordre et doublons possibles : consommateurs idempotents obligatoires ; débogage plus difficile.
3. **Base partagée (lecture croisée de schémas ou vues)** : un contexte lit directement les tables d'un autre.
   + Aucune infrastructure de plus.
   − Casse l'isolation des contextes et le contrat versionné ; un changement de table casse les autres ; interdit par ADR 0001.

## Décision

**Option 2** pour les échanges entre contextes. Les contrats sont versionnés (`.v1`), la livraison est au moins une fois (QoS 1), et chaque consommateur dédoublonne par l'identifiant de l'événement. **Exception assumée** : la Production demande les poids mesurés au Service d'ingestion par un appel HTTPS synchrone (relation Customer / Supplier de la context map), car elle a besoin d'une réponse immédiate pour afficher l'écart de rendement au coordinateur.

Justification : seule l'option 2 répond à la fois à la connectivité intermittente, aux consommateurs multiples de `MesureValidée.v1` et à la reprise après coupure, avec une infrastructure déjà fournie.

## Conséquences

+ Les contextes continuent de fonctionner quand l'un d'eux est arrêté.
+ Ajouter un consommateur ne modifie pas le producteur.
− Cohérence à terme : une alerte peut apparaître quelques secondes après la mesure.
− Chaque changement de contrat demande une nouvelle version (`.v2`) et une période de double publication.

À surveiller : retard de consommation par abonné (lag) ; nombre de messages en échec ou rejetés.

## Révision

Rouvrir si plus de 5 % des événements sont traités avec plus d'une minute de retard, ou si un contexte a besoin d'une réponse de moins de 500 ms d'un autre (l'appel synchrone de l'exception deviendrait alors la règle).