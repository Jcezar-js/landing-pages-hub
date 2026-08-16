# --- início: helper nosso (ícones inline no painel admin) ---
# Traço dos ícones do Lucide (licença ISC), colado aqui em vez de virar
# dependência: são poucos desenhos, e inline não custa requisição, não precisa
# de fonte de ícone e herda a cor do texto ao redor por `currentColor`.
#
# Só existe no painel: a LP pública tem outro layout e outro CSS.
module IconsHelper
  ICONS = {
    painel: '<rect width="7" height="9" x="3" y="3" rx="1"/><rect width="7" height="5" x="14" y="3" rx="1"/>' \
            '<rect width="7" height="9" x="14" y="12" rx="1"/><rect width="7" height="5" x="3" y="16" rx="1"/>',
    clientes: '<path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/>' \
              '<path d="M22 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/>',
    busca: '<circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/>',
    sair: '<path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><polyline points="16 17 21 12 16 7"/>' \
          '<line x1="21" x2="9" y1="12" y2="12"/>',
    novo: '<path d="M5 12h14"/><path d="M12 5v14"/>',
    editar: '<path d="M12 20h9"/><path d="M16.5 3.5a2.12 2.12 0 0 1 3 3L7 19l-4 1 1-4Z"/>',
    remover: '<path d="M3 6h18"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6"/>' \
             '<path d="M8 6V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/>',
    lp: '<path d="M4.5 16.5c-1.5 1.26-2 5-2 5s3.74-.5 5-2c.71-.84.7-2.13-.09-2.91a2.18 2.18 0 0 0-2.91 0z"/>' \
        '<path d="m12 15-3-3a22 22 0 0 1 2-3.95A12.88 12.88 0 0 1 22 2c0 2.72-.78 7.5-6 11a22.35 22.35 0 0 1-4 2z"/>' \
        '<path d="M9 12H4s.55-3.03 2-4c1.62-1.08 5 0 5 0"/><path d="M12 15v5s3.03-.55 4-2c1.08-1.62 0-5 0-5"/>',
    pendencia: '<path d="m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3"/>' \
               '<path d="M12 9v4"/><path d="M12 17h.01"/>',
    site: '<circle cx="12" cy="12" r="10"/><path d="M12 2a14.5 14.5 0 0 0 0 20 14.5 14.5 0 0 0 0-20"/>' \
          '<path d="M2 12h20"/>',
    mapa: '<path d="M20 10c0 6-8 12-8 12s-8-6-8-12a8 8 0 0 1 16 0"/><circle cx="12" cy="10" r="3"/>',
    nota: '<polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26"/>'
  }.freeze

  # `raw` é seguro aqui: o conteúdo vem só da constante acima, nunca de params.
  def icon(name)
    tag.svg(raw(ICONS.fetch(name)), class: "icon", viewBox: "0 0 24 24", fill: "none",
            stroke: "currentColor", "stroke-width": 2, "stroke-linecap": "round",
            "stroke-linejoin": "round", "aria-hidden": true)
  end
end
# --- fim: helper nosso ---
