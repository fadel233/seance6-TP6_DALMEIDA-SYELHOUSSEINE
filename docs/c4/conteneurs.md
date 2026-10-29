# Conteneurs de QueenBee (N2)

Auteurs : Abdoul DALMEIDA, El Housseine SY · Parcours Dev

## Tableau des conteneurs

| Conteneur | Technologie | Pourquoi séparé | Contextes hébergés | Données stockées |
|---|---|---|---|---|
| App terrain | React Native, SQLite chiffré | Autre lieu d'exécution (téléphone de l'apicultrice) et fonctionnement hors ligne (UC-A01). Autre cycle de vie (publication sur les stores) et autre public (utilisateurs peu familiers du numérique). | Terrain (côté client : saisie), vue des alertes de Santé | File locale des inspections, photos, cache des ruches et du jeton, chiffrés |
| Tableau de bord web | React (SPA), Leaflet | Autre public (coordinateurs, gestionnaires, administrateurs) et autre usage (grand écran, carte, tableaux). Se déploie sans toucher à l'app mobile. | aucun (interface) | aucune (état dans le navigateur) |
| API centrale | Node.js 22, Express, TypeScript | Point d'entrée unique des deux clients ; cycle de vie propre, déployé par la CI/CD ; sans état donc réplicable ; un seul code pour les règles métier des contextes cœur. | Référentiel ruchers, Santé des colonies, Terrain, Production, Identité et accès (modules) | aucune (sans état) : tout est dans la Base centrale |
| Service d'ingestion | Python 3.12, MQTT | Autre rythme de charge : flux continu de trames (≈ 27 mesures/min sur le réseau, pointes à 50 messages/min par site), sans lien avec les requêtes des utilisateurs. Autre cycle de vie : redémarrer l'API ne doit pas interrompre la validation. Règles d'intégrité (UC-CY02) isolées et portées par Data/Cyber. | Collecte des mesures (validation, incidents de site) | Mesures validées, trames rejetées, journal d'intégrité (schéma `mesures`) |
| Broker MQTT | MQTT, TLS | Autre lieu d'exécution (central, partagé) et découplage dans le temps : il retient les messages pendant une coupure et laisse les consommateurs rattraper leur retard. | aucun (transport des événements `.v1`) | Messages en transit et sessions persistantes (QoS 1) |
| Passerelle de site | ChirpStack, K3s ou Docker Compose | Autre lieu d'exécution : une instance par site (×8), sur des sites isolés, parfois sur panneaux solaires. Doit continuer sans le central (mode dégradé, cache local) et traiter l'acoustique en local (duty cycle LoRaWAN). | Collecte des mesures (côté site : trames, heartbeat, mode dégradé) | Cache local des mesures non transmises |
| Plateforme de données | Python 3.12, Airflow, dbt, scikit-learn | Autre langage et autre cycle de vie (réentraînement des modèles, versions de modèle). Autre rythme de charge : traitements par lot, indépendants du temps de réponse de l'API (< 500 ms). | Prévision, Impact et rapports | Modèles, prédictions, zone de staging |
| Entrepôt de données | PostgreSQL 16 | Stockage et profil de charge différents : requêtes analytiques lourdes (< 200 ms pour 90 %) qui ne doivent pas ralentir la base transactionnelle. Historisation en étoile. | aucun (stockage de Prévision et Impact) | Faits et dimensions : mesures, récoltes, alertes résolues |
| Orchestrateur de workflows | n8n | Cycle de vie propre : un workflow se modifie sans redéployer l'API. Isole les fournisseurs de notification et d'e-mail du reste du code (couche anti-corruption de la context map). Demandé par le CDC. | Messagerie (couche anti-corruption) | Workflows, secrets des fournisseurs |
| Supervision et SIEM | Prometheus, Grafana, Wazuh | Autre zone de confiance (Management, élevée) et autre public (administrateur). Doit survivre à la panne de ce qu'elle surveille. | aucun (transverse) | Métriques, journaux, alertes de sécurité |
| Base centrale | PostgreSQL 16, PostGIS | Stockage des données métier et des mesures ; PostGIS pour les positions et la dérive (UC-CY04). | Données de tous les contextes hébergés par l'API et l'ingestion | Sites, ruches, comptes, alertes, inspections, récoltes, mesures |

## Où vivent les bounded contexts du TP 5

| Bounded context | Type | Conteneur |
|---|---|---|
| Référentiel ruchers | support | API centrale (module) |
| Santé des colonies | cœur | API centrale (module) |
| Terrain | cœur | API centrale (module) + App terrain (client) |
| Production | support | API centrale (module) |
| Identité et accès | générique | API centrale (module) |
| Collecte des mesures | support | Service d'ingestion + Passerelle de site |
| Prévision | support | Plateforme de données |
| Impact et rapports | support | Plateforme de données |

Cinq des huit contextes tiennent dans un seul conteneur : c'est un **monolithe modulaire**. Les trois autres sont à part pour une raison technique (rythme de charge, lieu d'exécution, langage), jamais « parce que c'est un contexte ».

## Règle d'isolation des données

La Base centrale est une seule instance, mais avec **un schéma par contexte** et un rôle SQL par module. Aucun module ne lit le schéma d'un autre : la Production obtient les poids par l'API du Service d'ingestion (relation Customer / Supplier de la context map), pas par une jointure SQL.

## Ce qui n'est pas séparé

- **Identité et accès** reste un module de l'API centrale, sans service d'authentification dédié : 300 utilisateurs, un seul JWT à émettre, aucun besoin de charge ni de langage différent.
- **Les cinq contextes de l'API centrale** restent dans un seul déploiement : un conteneur de plus coûte du déploiement, de la supervision et de la sécurité.
- **Le reverse proxy / répartiteur de charge** du schéma 6.1 du CDC n'apparaît pas au N2 : c'est un détail de déploiement devant l'API et le tableau de bord, qui n'héberge aucune règle métier.

## Écart avec la context map du TP 5

La context map traite « Capteurs + passerelle LoRaWAN » comme un système externe. Au niveau N2, la passerelle est un conteneur que nous déployons et supervisons (CDC, section VI) : seuls les **capteurs** restent externes. La couche anti-corruption qui traduit la trame binaire en `Trame` se situe donc entre la Passerelle de site et le Service d'ingestion.
