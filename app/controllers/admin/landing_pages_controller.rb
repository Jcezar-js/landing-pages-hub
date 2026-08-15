# --- início: lógica nossa (CRUD aninhado de LandingPage + Sections no painel admin) ---
class Admin::LandingPagesController < ApplicationController
  BLANK_SECTION_SLOTS = 3

  before_action :set_client
  before_action :set_landing_page, only: %i[edit update destroy]

  def new
    @landing_page = @client.build_landing_page
    build_blank_sections
  end

  def create
    @landing_page = @client.build_landing_page(landing_page_params)

    if @landing_page.save
      redirect_to edit_admin_client_landing_page_path(@client)
    else
      build_blank_sections
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    build_blank_sections
  end

  def update
    if @landing_page.update(landing_page_params)
      redirect_to edit_admin_client_landing_page_path(@client)
    else
      build_blank_sections
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @landing_page.destroy
    redirect_to edit_admin_client_path(@client)
  end

  private

  def set_client
    @client = Client.find(params[:client_id])
  end

  def set_landing_page
    @landing_page = @client.landing_page || raise(ActiveRecord::RecordNotFound)
  end

  def build_blank_sections
    BLANK_SECTION_SLOTS.times { @landing_page.sections.build }
  end

  def landing_page_params
    params.require(:landing_page).permit(
      :slug,
      sections_attributes: %i[id component_type title data position _destroy]
    )
  end
end
# --- fim: lógica nossa ---
