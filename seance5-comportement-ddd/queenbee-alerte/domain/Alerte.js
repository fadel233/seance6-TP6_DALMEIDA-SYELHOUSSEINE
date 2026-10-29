// QueenBee · contexte « Santé des colonies »
// AGRÉGAT Alerte : racine unique, invariants protégés, événements du domaine.
// Le cycle de vie est géré avec le pattern State : AUCUN switch sur le statut.
//
//   LEVÉE ──assigner──▶ PRISE_EN_CHARGE ──résoudre──▶ RÉSOLUE
//     │                        ▲
//     └──escalader (≥ 48 h)──▶ ESCALADÉE ──assigner──┘

export const TYPES_DE_RISQUE = ['ESSAIMAGE', 'AFFAIBLISSEMENT', 'STRESS_THERMIQUE', 'MORTALITE'];
export const DELAI_ESCALADE_MS = 48 * 60 * 60 * 1000;

const iso = d => new Date(d).toISOString();
const MSG_NON_PRISE_EN_CHARGE = 'Une alerte doit être prise en charge avant d’être résolue';

// ---------------------------------------------------------------- états
const Levee = {
  nom: 'LEVÉE',
  assigner(alerte, apicultriceId, at) {
    alerte._passer(PriseEnCharge, { type: 'AlertePriseEnCharge', apicultriceId, at: iso(at) });
  },
  escalader(alerte, at) {
    if (!alerte.estEnRetard(at)) {
      throw new Error('Escalade refusée : l’alerte n’est pas restée 48 h sans prise en charge');
    }
    alerte._passer(Escaladee, { type: 'AlerteEscaladée', at: iso(at) });
  },
  resoudre() {
    throw new Error(MSG_NON_PRISE_EN_CHARGE);
  },
};

const PriseEnCharge = {
  nom: 'PRISE_EN_CHARGE',
  assigner() { throw new Error('Alerte déjà prise en charge'); },
  escalader() { throw new Error('Une alerte prise en charge ne peut pas être escaladée'); },
  resoudre(alerte, inspectionId, at) {
    if (!inspectionId) throw new Error('Une inspection est requise pour résoudre une alerte');
    alerte._passer(Resolue, { type: 'AlerteRésolue', inspectionId, at: iso(at) });
  },
};

const Escaladee = {
  nom: 'ESCALADÉE',
  assigner(alerte, apicultriceId, at) {
    alerte._passer(PriseEnCharge, { type: 'AlertePriseEnCharge', apicultriceId, at: iso(at) });
  },
  escalader() { throw new Error('Alerte déjà escaladée'); },
  resoudre() { throw new Error(MSG_NON_PRISE_EN_CHARGE); },
};

const Resolue = {
  nom: 'RÉSOLUE',
  assigner() { throw new Error('Alerte résolue : aucune transition possible'); },
  escalader() { throw new Error('Alerte résolue : aucune transition possible'); },
  resoudre() { throw new Error('Alerte résolue : aucune transition possible'); },
};

// ---------------------------------------------------------------- agrégat
export class Alerte {
  #etat = Levee;
  #events = [];

  constructor({ id, hiveId, siteId, risque, confiance, leveeLe }) {
    Object.assign(this, { id, hiveId, siteId, risque, confiance, leveeLe: new Date(leveeLe) });
  }

  /** Fabrique : seul moyen de créer une alerte valide. */
  static lever({ id, hiveId, siteId, type, confiance, at }) {
    if (!TYPES_DE_RISQUE.includes(type)) {
      throw new Error(`Type de risque inconnu : ${type}`);
    }
    if (typeof confiance !== 'number' || !Number.isFinite(confiance) || confiance < 0 || confiance > 1) {
      throw new Error('La confiance doit être un nombre compris entre 0 et 1');
    }
    const alerte = new Alerte({ id, hiveId, siteId, risque: type, confiance, leveeLe: at });
    alerte.#events.push({ type: 'AlerteLevée', alerteId: id, hiveId, siteId, risque: type, confiance, at: iso(at) });
    return alerte;
  }

  get statut() { return this.#etat.nom; }

  assigner(apicultriceId, at) { this.#etat.assigner(this, apicultriceId, at); }
  escalader(at) { this.#etat.escalader(this, at); }
  resoudre(inspectionId, at) { this.#etat.resoudre(this, inspectionId, at); }

  /** Règle métier : une alerte restée LEVÉE 48 h sans prise en charge est en retard. */
  estEnRetard(now) {
    return this.#etat === Levee && new Date(now).getTime() - this.leveeLe.getTime() >= DELAI_ESCALADE_MS;
  }

  /** Événements produits depuis le dernier appel (consommés une seule fois). */
  pullEvents() {
    const e = this.#events;
    this.#events = [];
    return e;
  }

  /** Réservé aux objets état de ce module : change d'état et enregistre l'événement. */
  _passer(etat, event) {
    this.#etat = etat;
    this.#events.push({ ...event, alerteId: this.id, hiveId: this.hiveId });
  }
}
