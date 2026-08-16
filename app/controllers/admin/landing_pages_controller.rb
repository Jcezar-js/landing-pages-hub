# --- início: lógica nossa (CRUD de LandingPage no painel admin) ---
# Só o slug: os blocos deixaram de ser editados aqui por nested attributes e
# passaram a ter tela própria (Admin::SectionsController), porque o formulário
# de cada bloco depende do component_type escolhido.
class Admin::LandingPagesController < ApplicationController
  layout "admin"

  before_action :set_client
  before_action :set_landing_page, only: %i[edit update destroy]

  def new
    @landing_page = @client.build_landing_page
  end

  def create
    @landing_page = @client.build_landing_page(landing_page_params)

    if @landing_page.save
      redirect_to edit_admin_client_landing_page_path(@client), notice: "Landing page criada."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @landing_page.update(landing_page_params)
      redirect_to edit_admin_client_landing_page_path(@client), notice: "Landing page atualizada."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @landing_page.destroy
    redirect_to edit_admin_client_path(@client), notice: "Landing page removida."
  end

  private

  def set_client
    @client = Client.find(params[:client_id])
  end

  def set_landing_page
    @landing_page = @client.landing_page || raise(ActiveRecord::RecordNotFound)
  end

  def landing_page_params
    params.require(:landing_page).permit(:slug)
  end
end
# --- fim: lógica nossa ---
