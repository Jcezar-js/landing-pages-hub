class ApplicationController < ActionController::Base
  before_action :authenticate_admin!

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  # --- início: lógica nossa (layout das telas do Devise) ---
  # Os controllers do Devise herdam daqui e não dá pra pôr `layout "auth"` neles
  # sem sobrescrever a gem. `devise_controller?` é helper da própria Devise.
  # Os controllers de admin declaram `layout "admin"` e ignoram isso.
  layout :layout_by_controller

  private

  def layout_by_controller
    devise_controller? ? "auth" : "application"
  end
  # --- fim: lógica nossa ---

  # --- início: lógica nossa (a aba lembra do último filtro usado) ---
  # A URL continua sendo a fonte de verdade da listagem (F5, favorito e o botão
  # voltar do navegador não mudam de comportamento). O que a session guarda é só
  # pra onde o link da sidebar aponta — trocar de aba e voltar devolve o admin
  # onde ele estava, em vez de uma lista pelada.
  #
  # Só as chaves conhecidas entram: query string é entrada de fora, e uma URL
  # forjada com params grandes estouraria o cookie de sessão (4 KB).
  FILTER_KEYS = %w[q lp sem_site page].freeze

  def remember_filters
    filters = request.query_parameters.slice(*FILTER_KEYS)
    session["filters/#{controller_name}"] = filters if filters.any?
  end

  def remembered_filters(name)
    session["filters/#{name}"] || {}
  end
  helper_method :remembered_filters
  # --- fim: lógica nossa ---
end
