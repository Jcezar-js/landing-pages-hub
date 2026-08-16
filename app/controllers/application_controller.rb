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
end
