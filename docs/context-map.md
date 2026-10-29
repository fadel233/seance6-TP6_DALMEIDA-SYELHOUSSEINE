# Context map QueenBee · groupe Dev-<n>

Auteurs : Abdoul DALMEIDA, El Housseine SY

```mermaid
flowchart LR
  REF["Référentiel ruchers<br/><small>support</small>"]
  COL["Collecte des mesures<br/><small>support</small>"]
  SAN["Santé des colonies<br/><small>cœur</small>"]
  PRE["Prévision<br/><small>support</small>"]
  TER["Terrain<br/><small>cœur</small>"]
  PRO["Production<br/><small>support</small>"]
  IMP["Impact et rapports<br/><small>support</small>"]
  IAM["Identité et accès<br/><small>générique</small>"]
  GW[["Capteurs + passerelle LoRaWAN"]]
  METEO[["OpenWeatherMap"]]
  MSG[["Messagerie / SMS / e-mail"]]

  GW -- "ACL · trames" --> COL
  METEO -- "ACL · météo" --> PRE
  REF -- "U/D · OHS : RucheEnregistrée.v1" --> COL
  COL -- "U/D · OHS, PL : MesureValidée.v1" --> SAN
  COL -- "U/D · PL : MesureValidée.v1" --> PRE
  COL -- "U/D · PL : MesureValidée.v1" --> IMP
  PRE -- "U/D · PL : RisqueDétecté.v1" --> SAN
  PRE -- "U/D · PL : PrédictionCalculée.v1" --> PRO
  PRO -- "U/D · PL : RécolteValidée.v1" --> PRE
  PRO -- "U/D · PL : RécolteValidée.v1" --> IMP
  SAN -- "U/D · OHS, PL : AlerteLevée.v1, AlerteEscaladée.v1" --> TER
  TER -- "Partnership : InspectionSynchronisée.v1" --> SAN
  SAN -- "U/D · PL : AlerteRésolue.v1" --> IMP
  PRO -- "Customer / Supplier : API poids mesurés" --> COL
  IAM -. "OHS : jeton JWT" .-> SAN
  IAM -. "Conformist : jeton JWT" .-> TER
  SAN -- "ACL · notifier" --> MSG
  PRO -- "ACL · notifier" --> MSG
```

## Relations
| Amont | Aval | Relation | Échange | Justification |
|---|---|---|---|---|
| Capteurs + passerelle | Collecte | ACL | trames LoRaWAN | format binaire propriétaire, traduit en `Trame` |
| OpenWeatherMap | Prévision | ACL | météo | modèle externe non maîtrisé |
| Référentiel | Collecte | U/D · OHS | RucheEnregistrée.v1 | ne valider que les ruches connues |
| Collecte | Santé / Prévision / Impact | U/D · OHS, PL | MesureValidée.v1 | plusieurs consommateurs, contrat versionné |
| Prévision | Santé | U/D · PL | RisqueDétecté.v1 | Santé lève l'alerte |
| Prévision | Production | U/D · PL | PrédictionCalculée.v1 | calcul de l'écart de rendement |
| Production | Prévision | U/D · PL | RécolteValidée.v1 | réentraîner le modèle |
| Santé | Terrain | U/D · OHS, PL | AlerteLevée.v1, AlerteEscaladée.v1 | visite anticipée, notification |
| Terrain | Santé | Partnership | InspectionSynchronisée.v1 | l'inspection résout l'alerte ; deux équipes livrent ensemble |
| Production | Collecte | Customer / Supplier | API poids mesurés | le coordinateur compare aux poids |
| Santé / Production | Impact | U/D · PL | AlerteRésolue, RécolteValidée.v1 | indicateurs |
| Identité | Santé / Terrain | OHS / Conformist | JWT et rôles | contexte générique |
| Santé / Production | Messagerie | ACL | commande Notifier | isoler le fournisseur |
