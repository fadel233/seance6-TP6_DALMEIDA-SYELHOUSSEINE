# ADR 0003 · Escalader les alertes non prises en charge à 48 h par un balayage périodique de la base, dans l'API centrale

- Statut : proposé · Date : 2026-10-27 · Auteurs : Abdoul DALMEIDA, El Housseine SY · Spécialité : Dev
- Élément du C4 : composant « Module Santé des colonies » de l'API centrale (N3), et sa flèche vers le « Bus d'événements » (`AlerteEscaladée.v1`)

## Contexte

- **Règle métier** (UC-A02, `bounded-contexts.md`) : une alerte non prise en charge sous 48 h est escaladée au coordinateur. L'agrégat `Alerte` interdit la résolution sans prise en charge, et « résolue » est un état terminal.
- **Point chaud 3** : où vit la politique d'escalade (tâche planifiée, file différée ou base) ? Si on se trompe, des escalades sont ratées quand le central redémarre.
- **Point chaud 5** (lié) : les 48 h se comptent depuis quel horodatage, surtout quand une passerelle en mode dégradé renvoie des mesures anciennes ?
- **Contraintes du CDC** : RTO < 8 h et RPO < 24 h (section 8.3), donc le central peut redémarrer ou être restauré à un état de la veille ; temps de réponse de l'API < 500 ms (p95) (section 8.1) ; 8 coordinateurs, 400 ruches, donc quelques centaines d'alertes ouvertes au plus ; l'apicultrice peut rester plusieurs jours hors ligne (UC-A01), c'est la raison d'être de l'escalade.
- **Hypothèse à confirmer avec BeeAfrica** : les 48 h partent de l'horodatage de levée de l'alerte, fixé par l'horloge du serveur (`levéeLe`), et non de la date de la mesure (`occurredAt`). Sinon, une mesure ancienne renvoyée après une coupure déclencherait une escalade immédiate.

## Options

1. **Balayage périodique dans l'API centrale (la plus simple)** : toutes les 15 min, le module Santé cherche les alertes `LEVÉE` dont `levéeLe` a plus de 48 h et les escalade.
   + L'échéance est une donnée de la base : rien n'est perdu au redémarrage ou à la restauration.
   + Aucun conteneur ni composant supplémentaire ; règle testable avec une horloge injectée.
   − Précision limitée au pas du balayage (≤ 15 min de retard).
   − Si l'API est répliquée, il faut empêcher deux balayages simultanés (verrou).
2. **Minuterie de 48 h par alerte, dans une file de messages à délai** : à la levée, on publie un message qui sera livré 48 h plus tard.
   + Échéance à la minute près.
   + Pas de requête périodique sur la base.
   − La file devient la source de vérité des échéances : après une restauration de la file ou de la base, les minuteries sont perdues ou désynchronisées.
   − Il faut annuler le message à la prise en charge, et le broker MQTT du projet ne programme pas de livraison différée : il faudrait ajouter un autre outil (par exemple RabbitMQ avec un plugin de délai).
3. **Workflow planifié dans n8n** : toutes les 15 min, n8n appelle un endpoint de l'API qui escalade.
   + Aucun conteneur ajouté (n8n existe déjà).
   − Une règle métier cœur vit hors du code versionné et testé ; l'escalade dépend de deux conteneurs au lieu d'un (si n8n est arrêté, rien n'est escaladé).

## Décision

**Option 1** : balayage périodique toutes les 15 min dans le module Santé des colonies, sur l'horloge du serveur, à partir de `levéeLe`.

Justification (détail dans `docs/evaluation/matrice.md`) : elle obtient le meilleur score pondéré (4,45 sur 5, contre 2,90 pour l'option 2 et 2,75 pour l'option 3), car elle est la seule dont l'échéance survit à un redémarrage et à une restauration sans reconstruction. L'option 2 ne passe devant que si la précision de l'échéance pèse plus de 73 % du choix, ce qui est peu plausible pour BeeAfrica : 15 min de retard représentent 0,5 % du délai de 48 h. L'option 3 est dominée : elle est moins bien notée que l'option 1 sur les trois scénarios.

Règles de mise en œuvre :
- L'escalade est **idempotente** : `UPDATE … WHERE statut = 'LEVÉE' AND levée_le < now() - interval '48 hours'` ; une alerte déjà escaladée ou prise en charge n'est jamais touchée deux fois.
- Un verrou (verrou consultatif PostgreSQL) garantit un seul balayage à la fois si l'API est répliquée.
- Un index partiel sur les alertes `LEVÉE` garde la requête très en dessous des 500 ms.
- `AlerteEscaladée.v1` porte une clé d'idempotence (identifiant de l'alerte) pour que la notification ne parte qu'une fois.

## Conséquences

+ L'état de l'échéance est unique et vit dans la base : sauvegarde, restauration et redémarrage le préservent.
+ Aucun conteneur supplémentaire à déployer, superviser ou sécuriser.
+ La règle se teste sur 48 h simulées avec une horloge injectée et le simulateur accéléré du CDC (section 6.6).
− Une escalade peut partir avec jusqu'à 15 min de retard.
− Une restauration à un état ancien (RPO de 24 h) peut ressusciter une alerte déjà escaladée : la notification doit rester idempotente.
− Pendant un déploiement de l'API, un balayage est sauté ; il est rattrapé au suivant.

À surveiller (Prometheus et Grafana) : l'âge de la plus vieille alerte `LEVÉE` au-delà de 48 h ; le retard d'escalade (p95) ; la durée d'un balayage.

## Révision

Rouvrir si l'une de ces conditions est mesurée :
- le retard d'escalade dépasse 30 min plus de deux fois sur un mois ;
- BeeAfrica exige une précision meilleure que 5 min ;
- le nombre d'alertes ouvertes dépasse 10 000 et la durée du balayage dépasse 5 s ;
- une deuxième échéance métier longue apparaît (rappels, délais d'investigation des écarts) : une file à délai se justifierait alors pour l'ensemble.