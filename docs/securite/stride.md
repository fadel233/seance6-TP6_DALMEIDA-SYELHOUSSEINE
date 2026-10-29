# Analyse de menaces STRIDE · QueenBee (parcours Dev)

Auteurs : Abdoul DALMEIDA, El Housseine SY · Vues de référence : `docs/c4/n2-conteneurs.png` et `docs/c4/n3-api-centrale.png`

# Zones de confiance

Les zones de site viennent de la section 6.3 du cahier des charges. Les zones du central ne sont pas définies par le CDC : elles sont une **hypothèse de l'équipe**.

| Conteneur | Zone | Confiance |
|---|---|---|
| App terrain | Internet mobile (téléphone de l'apicultrice) | faible |
| Tableau de bord web | Internet (navigateur de l'utilisateur) | faible |
| API centrale | Central, applicatif | moyenne |
| Service d'ingestion | Central, applicatif | moyenne |
| Orchestrateur de workflows (n8n) | Central, applicatif | moyenne |
| Broker MQTT | Central, DMZ (point d'arrivée des VPN de site) | faible |
| Passerelle de site | Site : DMZ locale (VLAN 10) et LAN applicatif (VLAN 20) | faible (DMZ) et moyenne (LAN) |
| Plateforme de données | Central, données | moyenne |
| Entrepôt de données | Central, données | moyenne |
| Base centrale | Central, données | moyenne |
| Supervision et SIEM | Management (VLAN 30 sur les sites, central) | élevée |
| Ruches connectées (système externe) | IoT (VLAN 40) | faible |
| FCM, service d'e-mail (systèmes externes) | Internet, non maîtrisé | faible |

# Flux qui franchissent une frontière

| Flux | De → vers | Protocole | Zones traversées |
|---|---|---|---|
| F1 | App terrain → API centrale | HTTPS/JSON, JWT | Internet mobile → Central applicatif |
| F2 | Tableau de bord web → API centrale | HTTPS/JSON, JWT | Internet → Central applicatif |
| F3 | Passerelle de site → Broker MQTT | MQTT sur VPN WireGuard | Site (DMZ locale) → Central DMZ |
| F4 | API centrale → n8n → FCM / service d'e-mail (chaîne de notification des alertes) | webhook HTTPS, puis HTTPS et SMTP | Central applicatif → Internet |

# Menaces

| Flux | STRIDE | Menace | Mesure | Réf. (UC, CDC, ADR) |
|---|---|---|---|---|
| F1 | S | Jeton volé sur un téléphone perdu ou volé : un tiers se fait passer pour l'apicultrice | Jeton d'accès de 15 min ; jeton de rafraîchissement lié à l'appareil (clé dans le Keystore / Keychain) et révocable par l'administrateur ; base locale chiffrée (SQLCipher) | UC-T01, CDC 8.2 |
| F1 | T | Lot d'inspections rejoué ou modifié : doublon ou valeur altérée à la synchronisation | TLS 1.3 ; chaque inspection porte un UUID généré par l'app et la version serveur connue : un doublon est accepté une seule fois, une version différente donne un 409 | UC-A01, `docs/sequences/synchronisation-inspection.md` |
| F1 | R | Une apicultrice nie avoir saisi ou modifié une inspection (bénéficiaires vulnérables, traçabilité complète exigée) | Journal d'audit côté serveur, horodaté par l'horloge serveur : compte, appareil, identifiant de l'inspection, version ; envoyé au SIEM (Wazuh) | UC-AD01, CDC 7.2 et 8.2 |
| F1 | D | Reconnexion simultanée des ≈ 50 apiculteurs d'un site après une coupure : l'API est saturée | Limitation de débit par compte et par IP ; lot plafonné à 100 inspections ; reprise avec attente croissante côté app ; objectif de synchronisation < 2 min pour un jour de données | CDC 8.1 |
| F1 | E | Un apiculteur synchronise ou lit une ruche d'un autre site en changeant l'identifiant dans la requête | Contrôle du droit par site à chaque requête (contrôleurs REST puis module Identité) ; test automatisé qui exige un 403 sur une ruche hors site | UC-AD01, CDC 8.2 (RBAC) |
| F2 | S | Mot de passe d'un coordinateur ou d'un administrateur deviné ou volé | MFA obligatoire pour les rôles à privilèges ; blocage du compte après 5 échecs | UC-T01, CDC 8.2 |
| F2 | I | Les positions GPS exactes des ruchers fuient par l'API et facilitent le vol de ruche | Coordonnées exactes retournées seulement aux rôles autorisés sur le site ; colonne de position chiffrée au repos dans la Base centrale | CDC 1.1, 8.2 et 8.4 |
| F3 | S | Passerelle usurpée qui publie de fausses mesures vers le broker | Authentification de chaque passerelle par certificat client (mTLS) et droits par sujet (`sites/<siteId>/#`) ; le Service d'ingestion rejette une trame dont le `site_id` ne correspond pas à l'identité du certificat. La décision relève de l'ADR Cyber du point chaud 10 (à écrire par Cyber) | UC-CY02, CDC 8.2, point chaud 10 |
| F3 | T | Trame falsifiée ou rejouée en transit | Contrôle de plage physique, compteur de trame et rejet des doublons à l'ingestion ; trame journalisée comme `TrameRejetée` | UC-CY02 |
| F3 | D | Rafale de messages après une longue coupure ou passerelle compromise : le broker et l'ingestion sont saturés | Limite de messages par client MQTT (50 messages/min par site) ; file de synchronisation avec priorité aux alertes critiques | CDC 4.6 (saturation de la file), 8.1 |
| F4 | I | Une notification push ou un e-mail expose des données de bénéficiaires chez un tiers (FCM, e-mail) | Minimisation : la notification porte le type d'alerte et son identifiant, jamais le nom ni la position ; le détail s'affiche après authentification dans l'app | CDC 8.4 |
| F4 | D | L'API ou n8n est arrêté à l'échéance de 48 h : l'alerte n'est jamais escaladée | Échéance stockée en base et balayage périodique idempotent toutes les 15 min dans l'API, qui rattrape tout après le redémarrage ; notification rejouée avec clé d'idempotence | UC-A02, CDC 8.3, **ADR 0003** |

# Risques résiduels

- **Téléphone volé avant d'être déclaré perdu** : les données locales restent protégées par le chiffrement et le jeton est court, mais un téléphone déverrouillé reste exploitable. Surveillé par l'administrateur (compte Identité) : délai entre la déclaration de perte et la révocation de l'appareil, cible < 24 h, revue mensuelle des appareils actifs.
- **Retard d'escalade jusqu'à 15 min** (accepté dans l'ADR 0003). Surveillé par le Dev (Grafana) : retard d'escalade p95 ; alerte si > 30 min.
- **Mesures falsifiées tant que l'authentification des passerelles n'est pas décidée** (ADR Cyber, point chaud 10). Surveillé par Cyber (SIEM) : nombre de `TrameRejetée` par passerelle et par jour.
- **Conflit de synchronisation : règle « qui gagne » non tranchée** (point chaud 12) : une inspection peut être refusée au lieu d'être fusionnée. Surveillé par le Dev : nombre de conflits 409 par site et par semaine.
- **Hypothèse sur les zones du central** : à valider avec l'équipe Cyber, car le CDC ne les définit pas.