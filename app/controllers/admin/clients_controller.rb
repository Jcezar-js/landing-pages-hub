# --- início: lógica nossa (CRUD de Client no painel admin) ---
class Admin::ClientsController < ApplicationController
  before_action :set_client, only: %i[edit update destroy]

  def index
    @clients = Client.all
  end

  def new
    @client = Client.new
  end

  def create
    @client = Client.new(client_params)

    if @client.save
      redirect_to edit_admin_client_path(@client)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @client.update(client_params)
      redirect_to edit_admin_client_path(@client)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @client.destroy
    redirect_to admin_clients_path
  end

  private

  def set_client
    @client = Client.find(params[:id])
  end

  def client_params
    params.require(:client).permit(:name, :email)
  end
end
# --- fim: lógica nossa ---
