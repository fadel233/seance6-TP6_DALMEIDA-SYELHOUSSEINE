# Glossaire QueenBee · groupe Dev-<n>

Auteurs : Abdoul DALMEIDA, El Housseine SY

| Terme | Définition validée | Contexte | Dans le code | Source |
|---|---|---|---|---|
| Ruche | Ruche physique identifiée (PPSITE-NNN), rattachée à un site, avec un capteur | Référentiel ruchers | `Ruche` | UC-AD01 |
| Colonie | Population d'abeilles vivant dans une ruche, dont on suit la santé | Santé des colonies | `Colonie` | UC-A02 |
| Site | Rucher géographique avec ses ruches et sa passerelle | Référentiel ruchers | `Site` | UC-G01 |
| Passerelle | Équipement LoRaWAN d'un site qui relaie les mesures vers le central | Collecte | `Passerelle` | UC-T02, UC-CY01 |
| Trame | Message brut reçu d'un capteur, avant validation | Collecte | `Trame` | UC-CY02 |
| Mesure validée | Trame dont la plage et l'unicité ont été vérifiées ; fait publié aux autres contextes | Collecte | `MesureValidee` | UC-T02 |
| Mode dégradé | Fonctionnement d'un site sur cache local quand sa passerelle est muette | Collecte | `ModeDegrade` | UC-CY01 |
| Alerte (colonie) | Signal qu'une colonie court un risque (type, confiance, recommandation), avec cycle de vie | Santé des colonies | `Alerte` | UC-A02 |
| Alerte de site (incident) | Signal d'un problème d'infrastructure (passerelle muette, brouillage, déplacement non déclaré) | Collecte | `IncidentSite` | UC-CY01 à CY04 |
| Type de risque | Nature du danger détecté (essaimage, affaiblissement…) | Santé des colonies | `TypeDeRisque` | UC-A02 |
| Niveau de confiance | Probabilité [0 ; 1] attachée à une prédiction ou une alerte | Santé des colonies | `confiance` | UC-A02 |
| Prise en charge | Engagement d'une apicultrice ou d'un apiculteur à traiter l'alerte | Santé des colonies | `alerte.assigner()` | UC-A02 |
| Escalade | Passage au coordinateur d'une alerte non prise en charge sous 48 h | Santé des colonies | `alerte.escalader()` | UC-A02 |
| Inspection | Visite constatée : état visuel, reine, comportement, photo | Terrain | `Inspection` | UC-A01 |
| Visite | Intervention planifiée et assignée sur une ruche | Terrain | `Visite` | UC-C01 |
| Synchronisation | Envoi au central des inspections saisies hors ligne | Terrain | `Synchronisation` | UC-A01 |
| Récolte | Volume de miel déclaré pour une ruche, à une date | Production | `Recolte` | UC-A03 |
| Écart de rendement | Différence en % entre récolte déclarée et prédiction | Production | `ecartRendement` | UC-A03 |
| Prédiction de rendement | Volume attendu pour une ruche et une saison | Prévision | `PredictionRendement` | UC-A03 |
| Risque détecté | Sortie du modèle : un risque probable sur une ruche, avec confiance | Prévision | `RisqueDetecte` | UC-A02 |
| Indicateur | Valeur consolidée multi-sites (rendement, colonies à risque, couverture) | Impact et rapports | `Indicateur` | UC-G01 |
| Rapport d'impact | Document PDF pour le bailleur sur une période et des sites | Impact et rapports | `Rapport` | UC-G02 |
| Compte | Identité d'une personne avec rôles et permissions par site | Identité et accès | `Compte` | UC-AD01 |
| Coordinateur | Responsable régional : visites, validation des récoltes, escalades | Identité et accès | `Role.COORDINATEUR` | UC-C01 |

## Mots à plusieurs sens
- **« Alerte »** : sens 1 dans *Santé des colonies* (risque sur une colonie, cycle LEVÉE → RÉSOLUE, 48 h d'escalade, traitée par l'apicultrice) ; sens 2 dans *Collecte* (incident d'infrastructure, traité par supervision et administrateur). **Décision : deux lignes, deux agrégats (`Alerte`, `IncidentSite`)**, parce que le cycle de vie, les acteurs et les règles diffèrent.
- **« Ruche »** : sens 1 dans *Référentiel* (objet physique, identifiant, site) ; sens 2 dans *Santé* (colonie suivie : score, historique). Décision : le Référentiel possède l'identité, Santé ne garde que `rucheId`.
- **« Site »** : sens 1 dans *Référentiel* (lieu, pays, ruches) ; sens 2 dans *Collecte* (périmètre d'une passerelle). Décision : même identifiant `siteId`, vues séparées.
- **« Validation »** : sens 1 dans *Collecte* (une mesure est valide : plage, doublon) ; sens 2 dans *Production* (le coordinateur accepte une récolte). Décision : `MesureValidée` et `RécolteValidée`, jamais « validation » seul.
- **« Incident »** : en Collecte (infrastructure) uniquement ; en Santé on dit « alerte ».
