class LandingPagesController < ApplicationController
  skip_before_action :authenticate_admin!, only: :show

  def show
    @landing_page = LandingPage.find_by!(slug: params[:slug])
  end
end
