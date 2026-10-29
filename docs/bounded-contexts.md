# Bounded contexts QueenBee

Auteurs : Abdoul DALMEIDA, El Housseine SY

## Référentiel ruchers
- Responsabilité : tenir la liste de référence des sites, ruches, capteurs, passerelles et déplacements déclarés.
- Type : support · spécialité la plus concernée : Data
- Agrégats : Site, Ruche (invariants : identifiant unique PPSITE-NNN ; une ruche dans un seul site)
- Événements publiés : RucheEnregistrée.v1, SiteCréé, DéplacementDéclaré
- Événements consommés : aucun
- UC sources : UC-AD01, UC-CY04
- Mots propres : ruche (objet physique), site

## Collecte des mesures
- Responsabilité : recevoir les trames LoRaWAN, les valider, publier les mesures et détecter les incidents d'infrastructure.
- Type : support · spécialité : Data / Cyber
- Agrégats : Trame (acceptée une seule fois ; plage physique), Passerelle (muette après 15 min), IncidentSite
- Événements publiés : MesureValidée.v1, TrameRejetée, PasserelleHorsLigne, BrouillageDétecté, DéplacementNonDéclaréDétecté
- Événements consommés : RucheEnregistrée.v1 (venant du Référentiel) ; trames de la passerelle (système externe, via ACL)
- UC sources : UC-T02, UC-CY01, UC-CY02, UC-CY03, UC-CY04
- Mots propres : trame, mode dégradé, alerte de site

## Santé des colonies (cœur)
- Responsabilité : suivre la santé de chaque colonie et gérer le cycle de vie des alertes.
- Type : cœur · spécialité : Dev
- Agrégats : Alerte (type connu, confiance [0 ; 1] ; pas de résolution sans prise en charge ; escalade après 48 h ; résolue = terminale), Colonie suivie (score entre 0 et 100)
- Événements publiés : AlerteLevée.v1, AlertePriseEnCharge, AlerteEscaladée.v1, AlerteRésolue.v1
- Événements consommés : MesureValidée.v1 (Collecte) ; RisqueDétecté.v1 (Prévision) ; InspectionSynchronisée.v1 (Terrain)
- UC sources : UC-A02
- Mots propres : alerte (colonie), prise en charge, escalade, score de santé

## Prévision
- Responsabilité : calculer les prédictions de rendement et les risques à partir des mesures et de la météo.
- Type : support (modèle externe encapsulé) · spécialité : Data
- Agrégats : Prédiction (liée à une ruche et une saison ; jamais modifiée)
- Événements publiés : PrédictionCalculée.v1, RisqueDétecté.v1
- Événements consommés : MesureValidée.v1 (Collecte) ; RécolteValidée.v1 (Production) ; météo (OpenWeatherMap, via ACL)
- UC sources : UC-A02, UC-A03
- Mots propres : prédiction de rendement, confiance

## Terrain (cœur)
- Responsabilité : planifier les visites et enregistrer les inspections, y compris hors ligne.
- Type : cœur · spécialité : Dev
- Agrégats : Visite (réalisée = figée), Inspection (ruche connue ; synchronisée = figée)
- Événements publiés : VisitePlanifiée, InspectionSynchronisée.v1, ConflitDeSynchronisationDétecté
- Événements consommés : AlerteLevée.v1, AlerteEscaladée.v1 (Santé)
- UC sources : UC-A01, UC-C01
- Mots propres : inspection, visite, synchronisation

## Production
- Responsabilité : déclarer, comparer et valider les récoltes.
- Type : support · spécialité : Dev
- Agrégats : Récolte (volume > 0 ; validée = figée ; écart signalé = commentaire)
- Événements publiés : RécolteDéclarée, RécolteValidée.v1, ÉcartMisEnInvestigation
- Événements consommés : PrédictionCalculée.v1 (Prévision) ; poids mesurés (API de Collecte)
- UC sources : UC-A03, UC-C02
- Mots propres : récolte, écart de rendement

## Impact et rapports
- Responsabilité : consolider les indicateurs multi-sites et produire les rapports pour les bailleurs.
- Type : support · spécialité : Data
- Agrégats : Rapport (période et sites non vides ; généré = immuable), Indicateur
- Événements publiés : RapportGénéré, RapportEnvoyéAuBailleur
- Événements consommés : MesureValidée.v1, RécolteValidée.v1, AlerteRésolue.v1
- UC sources : UC-G01, UC-G02
- Mots propres : indicateur, rapport d'impact

## Identité et accès
- Responsabilité : authentifier, gérer comptes, rôles par site, journal d'audit.
- Type : générique · spécialité : Cyber
- Agrégats : Compte (blocage après 5 échecs ; permissions par site)
- Événements publiés : CompteCréé, RôleAssigné, CompteBloqué
- Événements consommés : aucun
- UC sources : UC-AD01, UC-T01
- Mots propres : compte, rôle, permission
