class Admin::DashboardController < ApplicationController
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  # Admin-only: not applied to the public /lp/:slug route (ApplicationController),
  # which visitors on any browser must be able to reach.
  allow_browser versions: :modern

  def index
  end
end
