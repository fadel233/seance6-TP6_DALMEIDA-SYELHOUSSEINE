// Bus d'événements minimal (Observer) : on(type, handler) · emit(type, event)
export class EventBus {
  #handlers = new Map();
  on(type, handler) {
    if (!this.#handlers.has(type)) this.#handlers.set(type, []);
    this.#handlers.get(type).push(handler);
    return () => this.off(type, handler);
  }
  off(type, handler) {
    this.#handlers.set(type, (this.#handlers.get(type) ?? []).filter(h => h !== handler));
  }
  emit(type, event) {
    for (const h of this.#handlers.get(type) ?? []) h(event);
  }
}
