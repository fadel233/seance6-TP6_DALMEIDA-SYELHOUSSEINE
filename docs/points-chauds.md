# Points chauds
| # | Question | Impact si on se trompe | Qui peut répondre | Devient un ADR ? |
|---|---|---|---|---|
| 1 | Seuil d'écart de rendement : 20 % ? par coopérative ? | Alertes inutiles ou manquées | Coordinateurs BeeAfrica | non (paramètre) |
| 2 | « Alerte » : un ou deux sens ? | Agrégat incohérent | Équipe | non (tranché : deux sens) |
| 3 | Où vit la politique d'escalade à 48 h : tâche planifiée, file différée ou base ? | Escalades ratées si le central redémarre | Équipe | **oui (Dev)** |
| 4 | Comment l'application hors ligne reçoit-elle les alertes : push, synchronisation, file locale ? | Alerte lue trop tard | BeeAfrica, apicultrices | **oui (Dev)** |
| 5 | 48 h comptées depuis `occurredAt` ou `receivedAt` en mode dégradé ? | Escalade abusive | BeeAfrica | oui (lié à 3) |
| 6 | Mesures toutes les 30 min (UC-T02) ou 15 min (contrat Data) ? | Contrat de données faux | Client | non (clarification) |
| 7 | Qui prend en charge si aucune apicultrice n'est affectée à la ruche ? | Alerte orpheline | Coordinateurs | non |
| 8 | Une alerte peut-elle être annulée (fausse alerte) et par qui ? | Perte de traçabilité | Coordinateurs | non (état ANNULÉE) |
| 9 | Résolution manuelle sans inspection permise ? | Contournement de la règle | BeeAfrica | non |
| 10 | Authentification des passerelles : clé partagée, mTLS ou VPN ? | Usurpation de passerelle | Équipe sécurité | oui (Cyber) |
| 11 | Ingestion des mesures : lot ou flux ? | Latence des alertes | Équipe | oui (Data) |
| 12 | Conflit de synchronisation : qui gagne ? | Perte d'inspection | Apicultrices | oui |
