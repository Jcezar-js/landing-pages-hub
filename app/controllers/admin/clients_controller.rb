# --- início: lógica nossa (CRUD de Client no painel admin) ---
class Admin::ClientsController < ApplicationController
  layout "admin"

  PER_PAGE = 20

  before_action :set_client, only: %i[edit update destroy]
  before_action :remember_filters, only: :index

  # Busca (nome ou id), filtro por ter/não ter landing page e paginação por
  # limit/offset. Sem gem de paginação: são 3 linhas e a listagem só precisa de
  # "anterior/próxima". Trocar por `pagy` se um dia precisar de numeração.
  def index
    @page = [ params[:page].to_i, 1 ].max
    scope = filtered_clients

    @total = scope.count
    @total_pages = [ (@total / PER_PAGE.to_f).ceil, 1 ].max
    # `includes` evita 1 query por linha: a tabela mostra a landing page de cada cliente.
    @clients = scope.includes(:landing_page).order(:name).limit(PER_PAGE).offset((@page - 1) * PER_PAGE)
  end

  def new
    # Com params, veio da tela de prospecção: o form abre preenchido. Nada é
    # salvo aqui — o admin ainda confere e digita o email antes de submeter.
    @client = Client.new(params[:client] ? client_params : {})
  end

  def create
    @client = Client.new(client_params)

    if @client.save
      redirect_to edit_admin_client_path(@client), notice: "Cliente criado."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @client.update(client_params)
      redirect_to edit_admin_client_path(@client), notice: "Cliente atualizado."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @client.destroy
    redirect_to admin_clients_path, notice: "Cliente removido."
  end

  private

  def filtered_clients
    scope = Client.all

    if (query = params[:q].presence)
      # Colunas qualificadas: o filtro de LP abaixo adiciona um JOIN com
      # landing_pages, e `id` sem prefixo fica ambíguo entre as duas tabelas.
      scope = scope.where("clients.name ILIKE :like OR clients.id::text = :exact", like: "%#{query}%", exact: query)
    end

    # `where.associated`/`where.missing` são nativos do Rails 7+ — montam o
    # LEFT JOIN sozinhos, sem precisar escrever o join na mão.
    case params[:lp]
    when "com" then scope.where.associated(:landing_page)
    when "sem" then scope.where.missing(:landing_page)
    else scope
    end
  end

  def set_client
    @client = Client.find(params[:id])
  end

  def client_params
    params.require(:client).permit(:name, :email, :address, :phone, :website, :google_place_id)
  end
end
# --- fim: lógica nossa ---
