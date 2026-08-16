import { Controller } from "@hotwired/stimulus"

// --- início: código nosso (número do painel sobe até o valor final) ---
// O valor final já vem renderizado no HTML: sem JS a página mostra o número
// certo do mesmo jeito, o controller só anima a subida até ele. Respeita
// prefers-reduced-motion — animação aqui é enfeite, não informação.
export default class extends Controller {
  connect() {
    const target = Number(this.element.textContent)
    if (!Number.isFinite(target) || target === 0) return
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return

    const start = performance.now()
    const step = (now) => {
      const progress = Math.min((now - start) / 600, 1)
      this.element.textContent = Math.round(target * progress)
      if (progress < 1) requestAnimationFrame(step)
    }
    requestAnimationFrame(step)
  }
}
// --- fim: código nosso ---
