# Décision évaluée : Escalader les alertes à 48 h par un balayage périodique de la base, dans l'API centrale (ADR 0003)

Options comparées :
- **A** · Balayage périodique (toutes les 15 min) dans le module Santé de l'API centrale
- **B** · Minuterie de 48 h par alerte dans une file de messages à délai
- **C** · Workflow planifié n8n qui appelle l'API toutes les 15 min

## Scénarios de qualité

Les poids sont fixés **avant** les notes.

- S1 Fiabilité : API redémarrée, ou base restaurée à l'état de la veille (RPO < 24 h), pendant l'échéance → 100 % des alertes de plus de 48 h escaladées au plus tard 30 min après le retour du service · poids : 45 %
- S2 Précision : alerte `LEVÉE` non prise en charge → escalade déclenchée à 48 h avec un retard ≤ 15 min (0,5 % du délai) · poids : 30 %
- S3 Simplicité et testabilité : règle d'escalade testée sur 48 h simulées en moins d'une minute (simulateur ×60, horloge injectée), sans conteneur ni outil de plus à déployer et superviser · poids : 25 %

Pourquoi ces poids : l'escalade existe pour qu'aucune colonie en danger ne reste sans réponse (UC-A02), donc la fiabilité passe avant la précision. La précision compte moins, car 15 min sur 48 h est négligeable pour 8 coordinateurs. La simplicité pèse comme un quart parce que l'équipe est de deux personnes sur quatre mois.

## Matrice (notes de 1 à 5)

| Scénario (poids) | A · Balayage dans l'API | B · File à délai | C · Workflow n8n |
|---|---|---|---|
| S1 Fiabilité (45 %) | 5 | 2 | 3 |
| S2 Précision (30 %) | 4 | 5 | 3 |
| S3 Simplicité et testabilité (25 %) | 4 | 2 | 2 |
| **Score pondéré /5** | **4,45** | **2,90** | **2,75** |

Calcul : A = 0,45×5 + 0,30×4 + 0,25×4 = 4,45 · B = 0,45×2 + 0,30×5 + 0,25×2 = 2,90 · C = 0,45×3 + 0,30×3 + 0,25×2 = 2,75.

## Justification des notes (une phrase par note)

- **A · S1 = 5** : l'échéance est une colonne de la base, donc après un redémarrage ou une restauration le prochain balayage rattrape tout sans reconstruction.
- **A · S2 = 4** : le retard maximal est le pas du balayage (15 min), dans la cible mais pas à la minute.
- **A · S3 = 4** : aucune brique de plus et une horloge injectable, mais il faut un verrou si l'API est répliquée.
- **B · S1 = 2** : les minuteries vivent dans la file, donc une restauration de la file ou de la base les perd ou les désynchronise, et il faut les reconstruire à la main.
- **B · S2 = 5** : le message est livré à l'échéance, à la minute près.
- **B · S3 = 2** : le broker MQTT du projet ne programme pas de livraison différée, il faut un outil de plus, et l'annulation du message à la prise en charge ajoute un cas à tester.
- **C · S1 = 3** : l'état reste en base, mais l'escalade dépend aussi de la disponibilité de n8n : s'il est arrêté, rien n'est escaladé.
- **C · S2 = 3** : même pas de 15 min que A, plus la latence de l'appel réseau et de l'ordonnanceur de n8n.
- **C · S3 = 2** : pas de conteneur de plus, mais la règle cœur vit hors du code versionné, et un test sur 48 h simulées est difficile à automatiser.

## Sensibilité

- **A contre C** : A est au moins aussi bien noté que C sur les trois scénarios (5 contre 3, 4 contre 3, 4 contre 2). Aucun changement de poids ne fait gagner C : l'option 3 est dominée.
- **A contre B** : B ne passe devant que si S2 (la précision) pèse plus de **73 %**, en gardant la proportion de poids de S1 et S3. Exemple : avec S1 = 10 %, S3 = 10 % et S2 = 80 %, B obtient 4,40 contre 4,10 pour A (A = 0,10×5 + 0,80×4 + 0,10×4 ; B = 0,10×2 + 0,80×5 + 0,10×2). Condition générale : B gagne quand 3×w(S1) + 2×w(S3) < w(S2).
- **Plausible pour BeeAfrica ?** Non. Un retard de 15 min sur un délai de 48 h est négligeable pour 8 coordinateurs régionaux. Ce qui coûterait cher serait une escalade perdue, pas une escalade tardive de quelques minutes. Le seuil de 73 % de poids sur la précision correspondrait à une exigence d'échéance à la minute que rien dans le cahier des charges ne demande. Si BeeAfrica l'exigeait un jour (précision < 5 min), c'est un critère de révision de l'ADR.

## Conclusion → ADR 0003

L'option A (balayage périodique toutes les 15 min dans le module Santé) est retenue avec un score de 4,45 sur 5. Elle est reportée dans la section « Décision » de `adr/0003-escalader-a-48h-par-balayage-periodique-dans-lapi.md`.