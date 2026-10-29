# Mur QueenBee · version texte (≥ 40 événements)

Auteurs : Abdoul DALMEIDA, El Housseine SY
★ = événement pivot · (SE) = système externe · (P) = politique

## 1. Avant la saison (Référentiel ruchers, Identité et accès)
| # | Commande (acteur) | Agrégat | Événement |
|---|---|---|---|
| 1 | Créer un site (Administrateur) | Site | Site créé |
| 2 | Enregistrer une ruche (Administrateur) | Ruche | Ruche enregistrée ★ |
| 3 | Associer un capteur (Administrateur) | Ruche | Capteur associé à la ruche |
| 4 | Enregistrer une passerelle (Administrateur) | Passerelle | Passerelle enregistrée |
| 5 | Créer un compte (Administrateur) | Compte | Compte créé |
| 6 | Assigner un rôle par site (Administrateur) | Compte | Rôle assigné |
| 7 | Désactiver un compte (Administrateur) | Compte | Compte désactivé |
| 8 | S'authentifier (Tous) | Compte | Utilisateur authentifié |
| 9 | — (P) Après 5 échecs, bloquer | Compte | Compte bloqué |
| 10 | Déclarer un déplacement (Coordinateur) | Ruche | Déplacement déclaré |

## 2. En continu : collecte (Collecte)
| # | Cause | Agrégat | Événement |
|---|---|---|---|
| 11 | Capteur + passerelle LoRaWAN (SE) | Trame | Trame reçue |
| 12 | (P) Quand trame reçue, valider plage et doublon | Trame | Mesure validée ★ |
| 13 | (P) Si hors plage ou rejeu | Trame | Trame rejetée |
| 14 | (P) Si rejets répétés | Passerelle | Alerte d'intégrité levée |
| 15 | (P) Passerelle sans battement depuis 15 min | Passerelle | Passerelle déclarée hors ligne ★ |
| 16 | (P) Quand passerelle hors ligne | Passerelle | Mode dégradé activé |
| 17 | Passerelle (SE) rétablie | Passerelle | Passerelle rétablie |
| 18 | (P) Quand rétablie | Passerelle | Resynchronisation terminée |
| 19 | (P) Plus de mesure d'un capteur | Ruche suivie | Capteur déclaré silencieux |
| 20 | (P) Taux de trames perdues anormal | Passerelle | Brouillage détecté |
| 21 | (P) Quand brouillage | Passerelle | Changement de canal proposé |
| 22 | (P) Position GPS hors tolérance | Ruche suivie | Position hors tolérance détectée |
| 23 | (P) Si non déclaré | Incident de site | Déplacement non déclaré détecté ★ |
| 24 | (P) Quand déplacement non déclaré | Incident de site | Alerte prioritaire envoyée |
| 25 | Seuil dépassé (capteur) | Trame | Transmission immédiate déclenchée |

## 3. Quand un risque apparaît (Prévision, Santé des colonies)
| # | Cause | Agrégat | Événement |
|---|---|---|---|
| 26 | Modèle de prédiction (SE) | Prédiction | Prédiction de rendement calculée |
| 27 | Modèle de prédiction (SE) | Prédiction | Risque détecté ★ |
| 28 | OpenWeatherMap (SE) | Prédiction | Météo récupérée |
| 29 | (P) Quand mesure validée | Colonie suivie | Score de santé recalculé |
| 30 | (P) Quand score sous le seuil | Colonie suivie | Seuil dépassé |
| 31 | (P) Quand risque détecté, lever l'alerte | Alerte | Alerte levée ★ |
| 32 | Prendre en charge (Apicultrice) | Alerte | Alerte prise en charge |
| 33 | (P) Si aucune prise en charge sous 48 h | Alerte | Alerte escaladée ★ |
| 34 | (P) Quand inspection synchronisée | Alerte | Alerte résolue |
| 35 | Signaler fausse alerte (Coordinateur) | Alerte | Alerte annulée (extension) |
| 36 | (P) Quand alerte levée ou escaladée | Notification | Apicultrice notifiée · Coordinateur notifié |

## 4. Sur le terrain (Terrain)
| # | Cause | Agrégat | Événement |
|---|---|---|---|
| 37 | Planifier une visite (Coordinateur) | Visite | Visite planifiée |
| 38 | Assigner une visite (Coordinateur) | Visite | Visite assignée |
| 39 | (P) Quand alerte levée, proposer visite anticipée | Visite | Visite anticipée proposée |
| 40 | Enregistrer une inspection (Apicultrice, hors ligne) | Inspection | Inspection enregistrée hors ligne ★ |
| 41 | (P) Retour du réseau | Inspection | Inspection synchronisée |
| 42 | (P) Version serveur différente | Inspection | Conflit de synchronisation détecté |
| 43 | (P) Ruche inconnue | Inspection | Ruche introuvable signalée |
| 44 | (P) Anomalie dans l'inspection | Inspection | Anomalie d'inspection signalée |
| 45 | Réaliser la visite (Apicultrice) | Visite | Visite réalisée |

## 5. À la récolte (Production)
| # | Cause | Agrégat | Événement |
|---|---|---|---|
| 46 | Déclarer une récolte (Apicultrice) | Récolte | Récolte déclarée ★ |
| 47 | (P) Quand récolte déclarée | Récolte | Écart de rendement calculé |
| 48 | (P) Si écart > seuil | Récolte | Coordinateur notifié · Coopérative notifiée |
| 49 | Valider la récolte (Coordinateur) | Récolte | Récolte validée ★ |
| 50 | Signaler un écart (Coordinateur) | Récolte | Écart mis en investigation |

## 6. En fin de période (Impact et rapports)
| # | Cause | Agrégat | Événement |
|---|---|---|---|
| 51 | (P) Fin de période | Indicateurs | Indicateurs consolidés |
| 52 | Choisir période, sites, indicateurs (Gestionnaire) | Rapport | Période de rapport choisie |
| 53 | Générer le rapport (Gestionnaire) | Rapport | Rapport d'impact généré |
| 54 | Envoyer au bailleur (Gestionnaire) | Rapport | Rapport envoyé au bailleur |

## Écartés (étape B2)
Ligne insérée dans harvests (technique) · Bouton Valider cliqué (interface) · Miel récolté (doublon de Récolte déclarée) · Erreur 500 sur l'API (technique) · Données reçues (trop vague).

## Invariants des agrégats (≥ 2 chacun)
- **Alerte** : type de risque connu, confiance dans [0 ; 1] ; résolution seulement après prise en charge ; escalade seulement après 48 h ; une alerte résolue n'accepte plus de transition.
- **Inspection** : rattachée à une ruche connue ; une inspection synchronisée ne se modifie plus.
- **Visite** : une visite réalisée ne se replanifie pas ; assignée à une personne ayant un droit sur le site.
- **Ruche** : identifiant unique au format PPSITE-NNN ; appartient à un seul site à la fois.
- **Passerelle** : appartient à un site ; hors ligne après 15 min sans battement de cœur.
- **Trame** : une trame est acceptée une seule fois (hive_id + timestamp) ; valeurs dans la plage physique.
- **Récolte** : volume positif ; une récolte validée ne change plus ; un écart signalé exige un commentaire.
- **Rapport** : période et sites non vides ; un rapport généré est immuable.
- **Compte** : blocage après 5 échecs ; permissions par site.
- **Prédiction** : liée à une ruche et une saison ; une prédiction n'est jamais modifiée, on en calcule une nouvelle.



