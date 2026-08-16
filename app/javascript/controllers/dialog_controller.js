import { Controller } from "@hotwired/stimulus"

// --- início: lógica nossa (abre/fecha o <dialog> nativo do HTML) ---
// Não usa lib de modal: <dialog>.showModal() já entrega overlay, foco preso
// dentro do modal e fechamento por ESC. Stimulus só liga o clique ao elemento.
export default class extends Controller {
  static targets = ["dialog"]

  open() {
    this.dialogTarget.showModal()
  }

  close() {
    this.dialogTarget.close()
  }
}
// --- fim: lógica nossa ---
