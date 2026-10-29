# QueenBee · TP 5 Event Storming · parcours Dev

- Spécialité : Dev
- Membres : Abdoul DALMEIDA, El Housseine SY · groupe Dev-<n>

## Lancer le projet (Node ≥ 20)
```bash
npm run tp5         # 12 tests de l'agrégat Alerte
npm run lint:archi  # règle de dépendance : domain/ n'importe rien
npm run demo        # démonstration sur deux ruches
```

## Contenu
- `docs/` : mur (version texte), glossaire, bounded contexts, context map, points chauds, document Dev
- `seance5-comportement-ddd/queenbee-alerte/` : agrégat Alerte (State), service, repository, tests, démo
- `seance5-comportement-ddd/comportementaux/EventBus.js` : bus d'événements (Observer)
- `tools/` : lanceur de tests et vérificateur d'architecture

