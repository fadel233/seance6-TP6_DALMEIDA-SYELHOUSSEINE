workspace "QueenBee" "Plateforme apicole de BeeAfrica" {

    model {

        # ---------- Personnes : les 4 rôles du CDC (section III) ----------
        apicultrice = person "Apiculteur / Apicultrice" "Inspecte ses ruches, reçoit les alertes de risque et déclare ses récoltes, souvent sans connexion"
        coordinateur = person "Coordinateur régional" "Priorise et assigne les visites de son site, valide les récoltes déclarées"
        gestionnaire = person "Gestionnaire association" "Supervise tous les sites, consulte les analytics et produit les rapports pour les bailleurs"
        admin = person "Administrateur" "Gère comptes, rôles et seuils d'alerte, supervise déploiements, sécurité et journaux"

        # ---------- Systèmes externes (post-it roses du mur) ----------
        capteurs = softwareSystem "Ruches connectées" "400 capteurs LoRaWAN : poids, température, humidité, acoustique, position GPS" "Externe"
        meteo = softwareSystem "OpenWeatherMap" "Fournit la météo (canicule, pluie) pour la prévision" "Externe"
        fcm = softwareSystem "Firebase Cloud Messaging" "Distribue les notifications push différées" "Externe"
        mail = softwareSystem "Service d'e-mail" "Envoie les e-mails et les rapports aux bailleurs" "Externe"
        osm = softwareSystem "OpenStreetMap" "Fournit les fonds de carte des sites" "Externe"

        # ---------- QueenBee ----------
        queenbee = softwareSystem "QueenBee" "Suivi apicole connecté, prédictif et sécurisé pour BeeAfrica" {

            appTerrain = container "App terrain" "Saisie des inspections hors ligne, consultation des alertes et des ruches" "React Native, SQLite chiffré" "Mobile"
            dashboard = container "Tableau de bord web" "Carte multi-sites, priorisation des visites, validation des récoltes, analytics, administration" "React (SPA), Leaflet" "Web"
            api = container "API centrale" "Porte les règles métier : référentiel, santé des colonies, terrain, production, identité et accès" "Node.js 22, Express, TypeScript" {
                controleurs = component "Contrôleurs REST" "Expose les endpoints, valide le JWT, applique le RBAC par site" "Express" "Adaptateur"
                identite = component "Module Identité et accès" "Comptes, rôles par site, blocage après 5 échecs, journal d'audit" "TypeScript"
                referentiel = component "Module Référentiel ruchers" "Sites, ruches, capteurs, déplacements déclarés" "TypeScript"
                terrain = component "Module Terrain" "Visites, inspections hors ligne, détection des conflits de synchronisation" "TypeScript"
                sante = component "Module Santé des colonies" "Score de santé, cycle de vie des alertes, escalade à 48 h" "TypeScript"
                production = component "Module Production" "Déclaration et validation des récoltes, écart de rendement" "TypeScript"
                busInterne = component "Bus d'événements" "Distribue les événements .v1 entre modules et les relaie vers le broker" "TypeScript, MQTT.js" "Adaptateur"
                accesSql = component "Accès SQL" "Un dépôt et un rôle SQL par module : chacun ne touche que son schéma" "node-postgres" "Adaptateur"
            }
            ingestion = container "Service d'ingestion" "Valide les trames (plage, doublon, rejeu), détecte les incidents de site, publie les mesures validées" "Python 3.12, MQTT"
            broker = container "Broker MQTT" "Transporte les trames et les événements métier, retient les messages pendant une coupure" "MQTT 3.1.1/5, TLS"
            passerelle = container "Passerelle de site" "Reçoit le LoRaWAN, extrait les features acoustiques, met en cache et retransmet en différé" "ChirpStack, K3s ou Docker Compose" "Edge"
            donnees = container "Plateforme de données" "ETL, entraînement et prédiction (risques, rendement), indicateurs et rapports d'impact" "Python 3.12, Airflow, dbt, scikit-learn"
            n8n = container "Orchestrateur de workflows" "Envoie notifications et e-mails, déclenche l'envoi des rapports, isole les fournisseurs" "n8n"
            supervision = container "Supervision et SIEM" "Disponibilité des sites, métriques de déploiement, journaux et détection d'anomalies" "Prometheus, Grafana, Wazuh"
            baseCentrale = container "Base centrale" "Données métier et mesures validées, un schéma par contexte" "PostgreSQL 16, PostGIS" "Database"
            entrepot = container "Entrepôt de données" "Historisation analytique des mesures et des récoltes en étoile" "PostgreSQL 16" "Database"
        }

        # ---------- Relations niveau 1 (système) ----------
        apicultrice -> queenbee "Saisit les inspections et reçoit les alertes" "Application mobile, hors ligne"
        coordinateur -> queenbee "Priorise les visites et valide les récoltes" "HTTPS"
        gestionnaire -> queenbee "Consulte les analytics et génère les rapports" "HTTPS"
        admin -> queenbee "Gère les comptes et supervise la sécurité" "HTTPS"
        capteurs -> queenbee "Émettent poids, température, humidité, son et position" "LoRaWAN"
        queenbee -> meteo "Demande la météo" "HTTPS/JSON"
        queenbee -> fcm "Envoie les notifications push" "HTTPS"
        queenbee -> mail "Envoie les e-mails et les rapports" "SMTP"
        queenbee -> osm "Charge les fonds de carte" "HTTPS"

        # ---------- Relations niveau 2 (conteneurs) ----------
        apicultrice -> appTerrain "Saisit les inspections, consulte les alertes" "Application mobile"
        coordinateur -> dashboard "Priorise les visites, valide les récoltes" "HTTPS"
        gestionnaire -> dashboard "Consulte les analytics, génère les rapports" "HTTPS"
        admin -> dashboard "Gère comptes, rôles et seuils" "HTTPS"
        admin -> supervision "Surveille déploiements, sécurité et journaux" "HTTPS, MFA"

        appTerrain -> api "Synchronise les inspections, récupère les alertes" "HTTPS/JSON, JWT"
        dashboard -> api "Lit et modifie les données métier" "HTTPS/JSON, JWT"
        dashboard -> osm "Charge les fonds de carte" "HTTPS"

        api -> baseCentrale "Lit et écrit les données métier" "SQL, TLS"
        api -> broker "Publie et reçoit les événements métier" "MQTT, TLS"
        api -> ingestion "Demande les poids mesurés" "HTTPS/JSON"
        api -> donnees "Demande indicateurs et rapports" "HTTPS/JSON"
        api -> n8n "Demande l'envoi des notifications" "HTTPS (webhook)"

        capteurs -> passerelle "Émettent les trames de mesure" "LoRaWAN"
        passerelle -> broker "Transmet les mesures en différé" "MQTT sur VPN WireGuard"
        ingestion -> broker "Consomme les trames, publie les mesures validées" "MQTT, TLS"
        ingestion -> baseCentrale "Écrit les mesures validées et le journal d'intégrité" "SQL, TLS"

        donnees -> broker "Consomme les mesures, publie risques et prédictions" "MQTT, TLS"
        donnees -> entrepot "Charge et interroge l'entrepôt" "SQL, TLS"
        donnees -> meteo "Récupère la météo" "HTTPS/JSON"
        donnees -> n8n "Déclenche l'envoi des rapports" "HTTPS (webhook)"

        n8n -> fcm "Envoie les notifications push" "HTTPS"
        n8n -> mail "Envoie e-mails et rapports PDF" "SMTP"

        supervision -> passerelle "Surveille le heartbeat et collecte les journaux" "HTTPS et syslog sur VPN"
        supervision -> api "Collecte métriques et journaux" "HTTPS"

        # ---------- Relations niveau 3 (composants de l'API centrale) ----------
        appTerrain -> controleurs "Synchronise les inspections, récupère les alertes" "HTTPS/JSON, JWT"
        dashboard -> controleurs "Lit et modifie les données métier" "HTTPS/JSON, JWT"

        controleurs -> identite "Vérifie le jeton et les droits par site" "Appel de port"
        controleurs -> referentiel "Délègue les commandes sur sites et ruches" "Appel de port"
        controleurs -> terrain "Délègue la synchronisation des inspections" "Appel de port"
        controleurs -> sante "Délègue la consultation et la prise en charge des alertes" "Appel de port"
        controleurs -> production "Délègue déclaration et validation des récoltes" "Appel de port"

        identite -> accesSql "Lit et écrit le schéma identite" "SQL"
        referentiel -> accesSql "Lit et écrit le schéma referentiel" "SQL"
        terrain -> accesSql "Lit et écrit le schéma terrain" "SQL"
        sante -> accesSql "Lit et écrit le schéma sante" "SQL"
        production -> accesSql "Lit et écrit le schéma production" "SQL"
        accesSql -> baseCentrale "Exécute les requêtes, un rôle SQL par module" "SQL, TLS"

        identite -> busInterne "Publie CompteCréé, RôleAssigné, CompteBloqué" "Événement interne"
        referentiel -> busInterne "Publie RucheEnregistrée.v1" "Événement interne"
        terrain -> busInterne "Publie InspectionSynchronisée.v1" "Événement interne"
        sante -> busInterne "Publie AlerteLevée.v1, AlerteEscaladée.v1, AlerteRésolue.v1" "Événement interne"
        production -> busInterne "Publie RécolteValidée.v1" "Événement interne"
        busInterne -> terrain "Livre RucheEnregistrée.v1, AlerteLevée.v1, AlerteEscaladée.v1" "Événement interne"
        busInterne -> sante "Livre MesureValidée.v1, RisqueDétecté.v1, InspectionSynchronisée.v1" "Événement interne"
        busInterne -> production "Livre PrédictionCalculée.v1" "Événement interne"
        busInterne -> broker "Publie et reçoit les événements métier" "MQTT, TLS"

        production -> ingestion "Demande les poids mesurés" "HTTPS/JSON"
        sante -> n8n "Demande la notification des alertes" "HTTPS (webhook)"
        production -> n8n "Demande la notification des écarts" "HTTPS (webhook)"
    }

    views {

        systemContext queenbee "N1-Contexte" {
            title "N1 · Contexte de QueenBee"
            include *
            autolayout tb
        }

        container queenbee "N2-Conteneurs" {
            title "N2 · Conteneurs de QueenBee"
            include *
            autolayout tb
        }

        component api "N3-API-centrale" {
            title "N3 · Composants de l'API centrale"
            include *
            autolayout lr
        }

        styles {
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Component" {
                background #85bbf0
                color #000000
            }
            element "Adaptateur" {
                background #b9c7e6
                color #000000
            }
            element "Mobile" {
                shape MobileDevicePortrait
            }
            element "Web" {
                shape WebBrowser
            }
            element "Edge" {
                background #2e7d5b
            }
            element "Database" {
                shape Cylinder
            }
            element "Externe" {
                background #999999
                color #ffffff
            }
        }
    }
}
